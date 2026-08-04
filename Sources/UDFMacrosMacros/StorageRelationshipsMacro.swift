//
//  StorageRelationshipsMacro.swift
//  UDFMacros
//
//  Created by Oleksandr Bodnar on 29.07.2026.
//

import SwiftDiagnostics
import SwiftSyntax
import SwiftSyntaxMacros

// MARK: - Parsed relationship models

private struct ParsedHasOne {
    let parentTypeName: String
    let propertyName: String
    let argumentLabel: String
}

// mirrors ParsedHasOne. Kept as a separate type (not a shared enum) because
// hasOne/hasMany genuinely generate different code shapes downstream (storage
// value type, reduce-case bodies, accessor return type) — collapsing them into
// one type with a `kind` flag would just push an `if kind == .hasMany` into
// every codegen site instead of keeping each shape in its own place.
private struct ParsedHasMany {
    let parentTypeName: String
    let propertyName: String
    let argumentLabel: String
}

// MARK: - Macro

public struct StorageRelationshipsMacro: MemberMacro {
    public static func expansion(
        of node: AttributeSyntax,
        providingMembersOf declaration: some DeclGroupSyntax,
        in context: some MacroExpansionContext
    ) throws -> [DeclSyntax] {
        let hasStorageAttribute = declaration.attributes.contains { attribute in
            guard case let .attribute(attr) = attribute,
                  let identifier = attr.attributeName.as(IdentifierTypeSyntax.self)
            else { return false }
            return identifier.name.text == "Storage"
        }
        guard hasStorageAttribute else {
            context.diagnose(Diagnostic(node: node, message: StorageRelationshipsDiagnostic.requiresStorage))
            return []
        }

        guard let itemTypeName = storageItemTypeName(from: declaration) else {
            return []
        }

        guard case let .argumentList(arguments) = node.arguments else {
            return []
        }

        var hasOneRelationships: [ParsedHasOne] = []
        var hasManyRelationships: [ParsedHasMany] = []
        var usedPropertyNames: Set<String> = []
        // tracks parentTypeName across BOTH hasOne and hasMany. This is the
        // real collision surface — two relationships to the same parent type
        // generate the same `Actions.DidLoadNestedItem<Parent.ID, Item>` case
        // regardless of what the storage property is named.
        var usedParentTypeNames: Set<String> = []
        var sawError = false

        for argument in arguments {
            guard let call = argument.expression.as(FunctionCallExprSyntax.self),
                  let member = call.calledExpression.as(MemberAccessExprSyntax.self)
            else {
                context.diagnose(Diagnostic(node: argument, message: StorageRelationshipsDiagnostic.malformedArgument))
                sawError = true
                continue
            }

            let kind = member.declName.baseName.text
            guard kind == "hasOne" || kind == "hasMany" else {
                context.diagnose(Diagnostic(node: argument, message: StorageRelationshipsDiagnostic.malformedArgument))
                sawError = true
                continue
            }

            guard let firstArg = call.arguments.first,
                  let typeMemberAccess = firstArg.expression.as(MemberAccessExprSyntax.self),
                  typeMemberAccess.declName.baseName.text == "self",
                  let typeBase = typeMemberAccess.base?.as(DeclReferenceExprSyntax.self)
            else {
                context.diagnose(Diagnostic(node: argument, message: StorageRelationshipsDiagnostic.malformedArgument))
                sawError = true
                continue
            }
            let parentTypeName = typeBase.baseName.text

            guard usedParentTypeNames.insert(parentTypeName).inserted else {
                context.diagnose(Diagnostic(
                    node: argument,
                    message: StorageRelationshipsDiagnostic.duplicateParentType(parentTypeName)
                ))
                sawError = true
                continue
            }

            let explicitName = stringArgument(call, label: "name")
            let explicitLabel = stringArgument(call, label: "label")

            // Same default-naming scheme for both kinds: "by<Parent>Id".
            // No pluralization here — the key is always a single Parent.ID,
            // even for hasMany (the "many" lives in the value's OrderedSet).
            let propertyName = explicitName ?? "by\(parentTypeName)Id"
            let argumentLabel = explicitLabel ?? lowerCamelCase(parentTypeName)

            guard usedPropertyNames.insert(propertyName).inserted else {
                context.diagnose(Diagnostic(node: argument, message: StorageRelationshipsDiagnostic.duplicateName(propertyName)))
                sawError = true
                continue
            }

            if kind == "hasOne" {
                hasOneRelationships.append(ParsedHasOne(
                    parentTypeName: parentTypeName,
                    propertyName: propertyName,
                    argumentLabel: argumentLabel
                ))
            } else {
                hasManyRelationships.append(ParsedHasMany(
                    parentTypeName: parentTypeName,
                    propertyName: propertyName,
                    argumentLabel: argumentLabel
                ))
            }
        }

        guard !sawError else { return [] }

        let existingPropertyNames = existingStoredPropertyNames(in: declaration)
        let existingFunctionSignatures = existingFunctionSignatures(in: declaration)

        if existingFunctionSignatures.contains("_reduceRelationships(_)") {
            context.diagnose(Diagnostic(
                node: node,
                message: StorageRelationshipsDiagnostic.alreadyDeclared("_reduceRelationships(_:)")
            ))
            return []
        }

        var members: [DeclSyntax] = []

        // Storage properties — hasOne
        for relationship in hasOneRelationships where !existingPropertyNames.contains(relationship.propertyName) {
            members.append(DeclSyntax(stringLiteral:
                "var \(relationship.propertyName): [\(relationship.parentTypeName).ID: \(itemTypeName).ID] = [:]"
            ))
        }

        // Storage properties — hasMany
        for relationship in hasManyRelationships where !existingPropertyNames.contains(relationship.propertyName) {
            members.append(DeclSyntax(stringLiteral:
                "var \(relationship.propertyName): [\(relationship.parentTypeName).ID: OrderedSet<\(itemTypeName).ID>] = [:]"
            ))
        }

        // _reduceRelationships(_:) — both kinds combined into one switch.
        var reduceRelationshipsLines: [String] = [
            "mutating func _reduceRelationships(_ action: some Action) {",
            "    switch action {",
        ]
        for relationship in hasOneRelationships {
            reduceRelationshipsLines.append("    case let action as Actions.DidLoadNestedItem<\(relationship.parentTypeName).ID, \(itemTypeName)>:")
            reduceRelationshipsLines.append("        byId.insert(item: action.item)")
            reduceRelationshipsLines.append("        \(relationship.propertyName)[action.parentId] = action.item.id")
            reduceRelationshipsLines.append("")
        }
        // hasMany's three cases — additive (.append), matching the
        // union convention confirmed in AllDishes/AllReviews.
        for relationship in hasManyRelationships {
            reduceRelationshipsLines.append("    case let action as Actions.DidLoadNestedItem<\(relationship.parentTypeName).ID, \(itemTypeName)>:")
            reduceRelationshipsLines.append("        byId.insert(item: action.item)")
            reduceRelationshipsLines.append("        \(relationship.propertyName).append(action.item.id, by: action.parentId)")
            reduceRelationshipsLines.append("")

            reduceRelationshipsLines.append("    case let action as Actions.DidLoadNestedItems<\(relationship.parentTypeName).ID, \(itemTypeName)>:")
            reduceRelationshipsLines.append("        byId.insert(items: action.items)")
            reduceRelationshipsLines.append("        \(relationship.propertyName).append(action.items.ids, by: action.parentId)")
            reduceRelationshipsLines.append("")

            reduceRelationshipsLines.append("    case let action as Actions.DidLoadNestedByParents<\(relationship.parentTypeName).ID, \(itemTypeName)>:")
            reduceRelationshipsLines.append("        for (parentId, children) in action.dictionary {")
            reduceRelationshipsLines.append("            byId.insert(items: children)")
            reduceRelationshipsLines.append("            \(relationship.propertyName).append(children.ids, by: parentId)")
            reduceRelationshipsLines.append("        }")
            reduceRelationshipsLines.append("")
        }
        reduceRelationshipsLines.append("    default:")
        reduceRelationshipsLines.append("        break")
        reduceRelationshipsLines.append("    }")
        reduceRelationshipsLines.append("}")
        members.append(DeclSyntax(stringLiteral: reduceRelationshipsLines.joined(separator: "\n")))

        // Accessors — hasOne: singular, optional Item.ID?
        let accessorBaseName = "\(lowerCamelCase(itemTypeName))By"
        for relationship in hasOneRelationships {
            let signatureKey = "\(accessorBaseName)(\(relationship.argumentLabel))"
            guard !existingFunctionSignatures.contains(signatureKey) else { continue }
            let accessorLines = [
                "func \(accessorBaseName)(\(relationship.argumentLabel) id: \(relationship.parentTypeName).ID) -> \(itemTypeName).ID? {",
                "    \(relationship.propertyName)[id]",
                "}",
            ]
            members.append(DeclSyntax(stringLiteral: accessorLines.joined(separator: "\n")))
        }

        // Accessors — hasMany: pluralized name, [Item.ID] return.
        // Naive "+s" pluralization — cosmetic only (doesn't affect the storage
        // property name, which stays singular). Irregular plurals won't be
        // exact; the existing-signature escape hatch lets a hand-written
        // correctly-pluralized accessor override this one.
        let accessorManyBaseName = "\(pluralize(lowerCamelCase(itemTypeName)))By"
        for relationship in hasManyRelationships {
            let signatureKey = "\(accessorManyBaseName)(\(relationship.argumentLabel))"
            guard !existingFunctionSignatures.contains(signatureKey) else { continue }
            let accessorLines = [
                "func \(accessorManyBaseName)(\(relationship.argumentLabel) id: \(relationship.parentTypeName).ID) -> [\(itemTypeName).ID] {",
                "    Array(\(relationship.propertyName)[id] ?? [])",
                "}",
            ]
            members.append(DeclSyntax(stringLiteral: accessorLines.joined(separator: "\n")))
        }

        return members
    }

    // MARK: - Helpers (unchanged from the hasOne-only version)

    private static func stringArgument(_ call: FunctionCallExprSyntax, label: String) -> String? {
        call.arguments.first(where: { $0.label?.text == label })?
            .expression.as(StringLiteralExprSyntax.self)?
            .segments.first?.as(StringSegmentSyntax.self)?
            .content.text
    }

    private static func storageItemTypeName(from declaration: some DeclGroupSyntax) -> String? {
        for attribute in declaration.attributes {
            guard case let .attribute(attr) = attribute,
                  let identifier = attr.attributeName.as(IdentifierTypeSyntax.self),
                  identifier.name.text == "Storage",
                  case let .argumentList(args)? = attr.arguments,
                  let first = args.first,
                  let memberAccess = first.expression.as(MemberAccessExprSyntax.self),
                  memberAccess.declName.baseName.text == "self",
                  let base = memberAccess.base?.as(DeclReferenceExprSyntax.self)
            else { continue }
            return base.baseName.text
        }
        return nil
    }

    private static func existingStoredPropertyNames(in declaration: some DeclGroupSyntax) -> Set<String> {
        var names: Set<String> = []
        for member in declaration.memberBlock.members {
            guard let variable = member.decl.as(VariableDeclSyntax.self) else { continue }
            for binding in variable.bindings {
                if let identifier = binding.pattern.as(IdentifierPatternSyntax.self) {
                    names.insert(identifier.identifier.text)
                }
            }
        }
        return names
    }

    /// Matches on name + parameter labels (e.g. "_reduceRelationships(_)",
    /// "restaurantBy(review)") — the same fix already applied once in
    /// @Storage's own escape-hatch check, for the same reason: matching bare
    /// names alone would mistake unrelated overloads for each other.
    private static func existingFunctionSignatures(in declaration: some DeclGroupSyntax) -> Set<String> {
        var signatures: Set<String> = []
        for member in declaration.memberBlock.members {
            guard let function = member.decl.as(FunctionDeclSyntax.self) else { continue }
            let labels = function.signature.parameterClause.parameters
                .map { $0.firstName.text }
                .joined(separator: ",")
            signatures.insert("\(function.name.text)(\(labels))")
        }
        return signatures
    }

    private static func lowerCamelCase(_ name: String) -> String {
        guard let first = name.first else { return name }
        return first.lowercased() + name.dropFirst()
    }

    private static func pluralize(_ word: String) -> String {
        let lower = word.lowercased()
        if lower.hasSuffix("s") || lower.hasSuffix("x") || lower.hasSuffix("z")
            || lower.hasSuffix("ch") || lower.hasSuffix("sh")
        {
            return word + "es"
        }
        if lower.hasSuffix("y"), let beforeY = word.dropLast().last,
           !"aeiou".contains(beforeY.lowercased())
        {
            return String(word.dropLast()) + "ies"
        }
        return word + "s"
    }
}
