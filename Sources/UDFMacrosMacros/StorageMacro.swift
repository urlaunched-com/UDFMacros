import SwiftCompilerPlugin
import SwiftDiagnostics
import SwiftSyntax
import SwiftSyntaxBuilder
import SwiftSyntaxMacros

public struct StorageMacro: MemberMacro {
    public static func expansion(
        of node: AttributeSyntax,
        providingMembersOf declaration: some DeclGroupSyntax,
        conformingTo _: [TypeSyntax],
        in context: some MacroExpansionContext
    ) throws -> [DeclSyntax] {
        guard isSupportedDeclSyntax(declaration) else {
            context.diagnose(Diagnostic(node: Syntax(node), message: StorageDiagnostic.unsupportedType))
            return []
        }

        guard let itemTypeName = itemTypeName(from: node, context: context) else {
            context.diagnose(Diagnostic(node: Syntax(node), message: StorageDiagnostic.invalidArgument))
            return []
        }

        // Don't clobber members already written by hand — this is the escape
        // hatch for a storage that needs a bespoke `reduce` case alongside
        // the standard four (see the doc comment on `@Storage`).
        let existingNames = existingMemberNames(declaration)

        var members: [DeclSyntax] = []

        if !existingNames.contains("byId") {
            members.append(
                """
                var byId: [\(raw: itemTypeName).ID: \(raw: itemTypeName)] = [:]
                """
            )
        }

        if !existingNames.contains("reduce(_:)") {
            let defaultCase = existingNames.contains("reduceCustom(_:)")
                ? "reduceCustom(action)"
                : "break"

            members.append(
                """
                mutating func reduce(_ action: some Action) {
                    switch action {
                    case let action as Actions.DidLoadItems<\(raw: itemTypeName)>:
                        byId.insert(items: action.items)

                    case let action as Actions.DidLoadItem<\(raw: itemTypeName)>:
                        byId.insert(item: action.item)

                    case let action as Actions.DidUpdateItem<\(raw: itemTypeName)>:
                        byId[action.item.id] = action.item

                    case let action as Actions.DeleteItem<\(raw: itemTypeName)>:
                        byId.removeValue(forKey: action.item.id)

                    default:
                        \(raw: defaultCase)
                    }
                }
                """
            )
        }

        let accessorName = "\(lowerCamelCase(itemTypeName))By"

        if !existingNames.contains("\(accessorName)(id:)") {
            members.append(
                """
                func \(raw: accessorName)(id: \(raw: itemTypeName).ID) -> \(raw: itemTypeName) {
                    byId[id] ?? .empty
                }
                """
            )
        }

        return members
    }

    /// `Dish` -> `dish`, `FAQItem` -> `faqItem`. Only the leading run of
    /// uppercase letters is lowered, so acronym-led names stay readable.
    private static func lowerCamelCase(_ typeName: String) -> String {
        guard let first = typeName.first else { return typeName }

        if typeName.count == 1 {
            return typeName.lowercased()
        }

        let leadingUppercaseRun = typeName.prefix { $0.isUppercase }

        if leadingUppercaseRun.count <= 1 {
            return first.lowercased() + typeName.dropFirst()
        }

        // Keep the last uppercase letter of the run attached to the next word
        // (e.g. "FAQItem" -> leading run "FAQI", back off one -> "FAQ" + "Item").
        let wordBoundary = typeName.index(before: leadingUppercaseRun.endIndex)
        return typeName[..<wordBoundary].lowercased() + typeName[wordBoundary...]
    }

    /// Expects exactly one argument shaped like `Movie.self`.
    private static func itemTypeName(
        from node: AttributeSyntax,
        context _: some MacroExpansionContext
    ) -> String? {
        guard
            let arguments = node.arguments?.as(LabeledExprListSyntax.self),
            arguments.count == 1,
            let firstArg = arguments.first,
            let memberAccess = firstArg.expression.as(MemberAccessExprSyntax.self),
            memberAccess.declName.baseName.text == "self",
            let base = memberAccess.base?.as(DeclReferenceExprSyntax.self)
        else {
            return nil
        }

        return base.baseName.text
    }

    private static func existingMemberNames(_ declaration: some DeclGroupSyntax) -> Set<String> {
        var names: Set<String> = []

        for member in declaration.memberBlock.members {
            if let varDecl = member.decl.as(VariableDeclSyntax.self) {
                for binding in varDecl.bindings {
                    if let identifier = binding.pattern.as(IdentifierPatternSyntax.self) {
                        names.insert(identifier.identifier.text)
                    }
                }
            } else if let funcDecl = member.decl.as(FunctionDeclSyntax.self) {
                names.insert(functionSignature(funcDecl))
            }
        }

        return names
    }

    /// Builds a name+labels key (e.g. "restaurantBy(id:)", "reduce(_:)") so
    /// overloads sharing a base name — `restaurantBy(review:)` vs the
    /// macro's own `restaurantBy(id:)` — aren't mistaken for the same
    /// member. Matching on bare name here previously caused the macro to
    /// silently skip generating `restaurantBy(id:)` whenever any other
    /// `restaurantBy(...)` overload already existed.
    private static func functionSignature(_ funcDecl: FunctionDeclSyntax) -> String {
        let labels = funcDecl.signature.parameterClause.parameters.map { param in
            param.firstName.text == "_" ? "_" : param.firstName.text
        }
        return "\(funcDecl.name.text)(\(labels.map { "\($0):" }.joined()))"
    }

    private static func isSupportedDeclSyntax(_ decl: DeclGroupSyntax) -> Bool {
        decl.is(StructDeclSyntax.self)
    }
}
