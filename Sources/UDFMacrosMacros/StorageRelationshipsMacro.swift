//
//  StorageRelationshipsMacro.swift
//  UDFMacros
//
//  Created by Oleksandr Bodnar on 29.07.2026.
//

import SwiftDiagnostics
import SwiftSyntax
import SwiftSyntaxMacros

// MARK: - Parsed relationship model

private struct ParsedHasOne {
    let parentTypeName: String
    /// Storage dictionary name, e.g. "byReviewId". Matches the established
    /// `by<ParentType>Id` convention seen in hand-written relationships
    /// (byReviewId, byFortuneResultId, byDishId).
    let propertyName: String
    /// Accessor argument label, e.g. "review". NOT mechanically derived from
    /// parentTypeName by default in every case in the existing codebase
    /// (`fortuneResult` for FortuneWheelResult, `dishID` for Dish) — so this
    /// is independently overridable via `label:`, not tied to `propertyName`.
    let argumentLabel: String
}

// MARK: - Macro

public struct StorageRelationshipsMacro: MemberMacro {
    public static func expansion(
        of node: AttributeSyntax,
        providingMembersOf declaration: some DeclGroupSyntax,
        in context: some MacroExpansionContext
    ) throws -> [DeclSyntax] {
        // 1. Symmetric check: @Storage must be present on the same declaration.
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

        // 2. Pull the item type out of the sibling @Storage(Item.self) attribute.
        guard let itemTypeName = storageItemTypeName(from: declaration) else {
            // @Storage's own macro already diagnoses a malformed argument.
            return []
        }

        guard case let .argumentList(arguments) = node.arguments else {
            return []
        }

        var relationships: [ParsedHasOne] = []
        var usedPropertyNames: Set<String> = []
        var sawError = false

        for argument in arguments {
            guard let call = argument.expression.as(FunctionCallExprSyntax.self),
                  let member = call.calledExpression.as(MemberAccessExprSyntax.self)
            else {
                context.diagnose(Diagnostic(node: argument, message: StorageRelationshipsDiagnostic.malformedArgument))
                sawError = true
                continue
            }

            switch member.declName.baseName.text {
            case "hasMany":
                context.diagnose(Diagnostic(node: argument, message: StorageRelationshipsDiagnostic.hasManyNotYetSupported))
                sawError = true
                continue
            case "hasOne":
                break
            default:
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

            let explicitName = stringArgument(call, label: "name")
            let explicitLabel = stringArgument(call, label: "label")

            let propertyName = explicitName ?? "by\(parentTypeName)Id"
            let argumentLabel = explicitLabel ?? lowerCamelCase(parentTypeName)

            guard usedPropertyNames.insert(propertyName).inserted else {
                context.diagnose(Diagnostic(node: argument, message: StorageRelationshipsDiagnostic.duplicateName(propertyName)))
                sawError = true
                continue
            }

            relationships.append(ParsedHasOne(
                parentTypeName: parentTypeName,
                propertyName: propertyName,
                argumentLabel: argumentLabel
            ))
        }

        guard !sawError else { return [] }

        // 3. Escape hatch, symmetric with @Storage's own: don't regenerate
        //    members already written by hand. Matched by full signature.
        let existingPropertyNames = existingStoredPropertyNames(in: declaration)
        let existingFunctionSignatures = existingFunctionSignatures(in: declaration)

        if existingFunctionSignatures.contains("reduceRelationships(_)") {
            context.diagnose(Diagnostic(
                node: node,
                message: StorageRelationshipsDiagnostic.alreadyDeclared("reduceRelationships(_:)")
            ))
            return []
        }

        var members: [DeclSyntax] = []

        // 4. Storage property per relationship — `var by<Parent>Id: [Parent.ID: Item.ID]`.
        for relationship in relationships where !existingPropertyNames.contains(relationship.propertyName) {
            members.append(DeclSyntax(stringLiteral:
                "var \(relationship.propertyName): [\(relationship.parentTypeName).ID: \(itemTypeName).ID] = [:]"
            ))
        }

        // 5. Combined reduceRelationships(_:) — composes with @Storage's
        //    default: branch without colliding with a user-written reduceCustom(_:).
        //
        //    Only Actions.DidLoadNestedItem<ParentId, Nested> is generated here —
        //    it's the one confirmed to exist in UDFMacros/UDF's own Actions.swift.
        //    A bulk "by parents" load is deliberately NOT generated: that action
        //    (however it's named/shaped) lives at the app level, not the framework
        //    level, and its shape isn't standardized across apps — generating a
        //    reference to it would break compilation wherever it doesn't exist or
        //    doesn't match. If a relationship needs bulk-load handling, add that
        //    case by hand in reduceCustom(_:), which still sees byId/by<Parent>Id.
        //
        //    Built as a flat line array + single DeclSyntax(stringLiteral:) rather
        //    than a multi-line \(raw:) interpolation embedded inside more literal
        //    template text — the latter caused a real indentation bug (default:/
        //    break picked up extra leading spaces) since a multi-line raw
        //    interpolation followed by more outer-literal lines in the same
        //    triple-quote doesn't compose the way a single self-contained literal
        //    does (which is how @Storage's own reduce() cases are written).
        var reduceRelationshipsLines: [String] = [
            "mutating func reduceRelationships(_ action: some Action) {",
            "    switch action {",
        ]
        for relationship in relationships {
            reduceRelationshipsLines.append("    case let action as Actions.DidLoadNestedItem<\(relationship.parentTypeName).ID, \(itemTypeName)>:")
            reduceRelationshipsLines.append("        byId.insert(item: action.item)")
            reduceRelationshipsLines.append("        \(relationship.propertyName)[action.parentId] = action.item.id")
            reduceRelationshipsLines.append("")
        }
        reduceRelationshipsLines.append("    default:")
        reduceRelationshipsLines.append("        break")
        reduceRelationshipsLines.append("    }")
        reduceRelationshipsLines.append("}")
        members.append(DeclSyntax(stringLiteral: reduceRelationshipsLines.joined(separator: "\n")))

        // 6. Accessor per relationship — overload of `<item>By(...)`, matching
        //    @Storage's own accessor base name (e.g. `restaurantBy(id:)`).
        //    Returns Item.ID?, matching the hand-written accessors.
        let accessorBaseName = "\(lowerCamelCase(itemTypeName))By"
        for relationship in relationships {
            let signatureKey = "\(accessorBaseName)(\(relationship.argumentLabel))"
            guard !existingFunctionSignatures.contains(signatureKey) else { continue }
            let accessorLines = [
                "func \(accessorBaseName)(\(relationship.argumentLabel) id: \(relationship.parentTypeName).ID) -> \(itemTypeName).ID? {",
                "    \(relationship.propertyName)[id]",
                "}",
            ]
            members.append(DeclSyntax(stringLiteral: accessorLines.joined(separator: "\n")))
        }

        return members
    }

    // MARK: - Helpers

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

    /// Matches on name + parameter labels (e.g. "reduceRelationships(_)",
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
}
