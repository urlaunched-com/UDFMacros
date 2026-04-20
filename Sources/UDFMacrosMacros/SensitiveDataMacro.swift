import SwiftCompilerPlugin
import SwiftDiagnostics
import SwiftSyntax
import SwiftSyntaxBuilder
import SwiftSyntaxMacros

public struct SensitiveDataMacro: ExtensionMacro {
    private static let sensitiveAttributeName = "SensitiveField"

    public static func expansion(
        of node: AttributeSyntax,
        attachedTo declaration: some DeclGroupSyntax,
        providingExtensionsOf type: some TypeSyntaxProtocol,
        conformingTo _: [TypeSyntax],
        in context: some MacroExpansionContext
    ) throws -> [ExtensionDeclSyntax] {
        guard isSupportedDeclSyntax(declaration) else {
            context.diagnose(Diagnostic(node: Syntax(node), message: SensitiveActionDiagnostic.unsupportedType))
            return []
        }

        let structName = getDeclarationName(declaration)

        let fields = declaration.memberBlock.members.compactMap {
            $0.decl.as(VariableDeclSyntax.self)
        }

        let isMaskedEnabled = self.isMaskedEnabled(node: node)
        let maskedFieldDescriptions = getFieldDescriptions(variables: fields, masked: isMaskedEnabled) ?? ""
        let plainFieldDescriptions = getFieldDescriptions(variables: fields, masked: false) ?? ""

        let descriptionDecl = propertyStringDeclSyntax(
            name: "description",
            structName: structName,
            fieldDescriptions: maskedFieldDescriptions
        )

        let maskedDescriptionDecl = propertyStringDeclSyntax(
            name: "maskedDescription",
            structName: structName,
            fieldDescriptions: maskedFieldDescriptions
        )

        let plainDescriptionDecl = propertyStringDeclSyntax(
            name: "plainDescription",
            structName: structName,
            fieldDescriptions: plainFieldDescriptions
        )

        let ext = DeclSyntax(
            """
            extension \(type.trimmed): CustomStringConvertible {
                \(descriptionDecl)

                \(maskedDescriptionDecl)

                \(plainDescriptionDecl)
            }
            """
        )

        return [ext.cast(ExtensionDeclSyntax.self)]
    }

    private static func isMaskedEnabled(node: AttributeSyntax) -> Bool {
        guard
            let args = node.arguments?.as(LabeledExprListSyntax.self),
            let option = args.first?.expression.as(MemberAccessExprSyntax.self)?.declName.baseName.text
        else {
            return true
        }

        let shouldDisbaleMaskingFields = SensitiveDataOption(rawValue: option) == .disabledInDebug

        #if DEBUG
            return !shouldDisbaleMaskingFields
        #else
            return true
        #endif
    }

    private static func isSensitive(variable: VariableDeclSyntax) -> Bool {
        variable.attributes.contains {
            $0.as(AttributeSyntax.self)?
                .attributeName
                .as(IdentifierTypeSyntax.self)?
                .name.text == sensitiveAttributeName
        }
    }

    private static func getFieldDescriptions(variables: [VariableDeclSyntax], masked: Bool) -> String? {
        let descriptions = variables.flatMap { variable -> [String] in
            let names = variable.bindings.compactMap {
                $0.pattern.as(IdentifierPatternSyntax.self)?.identifier.text
            }
            let sensitive = isSensitive(variable: variable)

            return names.map { name in
                if sensitive, masked {
                    return #""\#(name): *****""#
                } else {
                    return #""\#(name): \(self.\#(name))""#
                }
            }
        }
        return descriptions.isEmpty ? nil : descriptions.joined(separator: #" + ", " + "#)
    }

    private static func propertyStringDeclSyntax(name: String, structName: String, fieldDescriptions: String) -> VariableDeclSyntax {
        VariableDeclSyntax(
            modifiers: DeclModifierListSyntax {
                DeclModifierSyntax(name: .keyword(.public, trailingTrivia: .space))
            },
            bindingSpecifier: .keyword(.var, trailingTrivia: .space)
        ) {
            PatternBindingSyntax(
                pattern: IdentifierPatternSyntax(identifier: .identifier(name)),
                typeAnnotation: TypeAnnotationSyntax(
                    type: IdentifierTypeSyntax(name: .identifier("String"))
                ),
                accessorBlock: AccessorBlockSyntax(
                    accessors: .getter(CodeBlockItemListSyntax(itemsBuilder: {
                        StmtSyntax(
                            """
                            return "\(raw: structName)(" + \(raw: fieldDescriptions) + ")"
                            """
                        )
                    }))
                )
            )
        }
    }

    private static func isSupportedDeclSyntax(_ decl: DeclGroupSyntax) -> Bool {
        let supportedDeclarationKinds: [any DeclSyntaxProtocol.Type] = [
            ClassDeclSyntax.self,
            StructDeclSyntax.self,
        ]
        return supportedDeclarationKinds.contains { decl.is($0) }
    }

    private static func getDeclarationName(_ decl: DeclGroupSyntax) -> String {
        switch decl.kind {
        case .classDecl:
            return decl.as(ClassDeclSyntax.self)?.name.text ?? ""
        case .structDecl:
            return decl.as(StructDeclSyntax.self)?.name.text ?? ""
        default:
            return ""
        }
    }
}

public struct SensitiveFieldMacro: PeerMacro {
    public static func expansion(
        of _: AttributeSyntax,
        providingPeersOf _: some DeclSyntaxProtocol,
        in _: some MacroExpansionContext
    ) throws -> [DeclSyntax] {
        []
    }
}
