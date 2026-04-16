import SwiftCompilerPlugin
import SwiftSyntax
import SwiftSyntaxBuilder
import SwiftSyntaxMacros
import SwiftDiagnostics

public struct SensitiveActionMacro: ExtensionMacro {
  private static let sensitiveAttributeName = "SensitiveField"
  
  public static func expansion(
    of node: AttributeSyntax,
    attachedTo declaration: some DeclGroupSyntax,
    providingExtensionsOf type: some TypeSyntaxProtocol,
    conformingTo protocols: [TypeSyntax],
    in context: some MacroExpansionContext
  ) throws -> [ExtensionDeclSyntax] {
    guard let structDecl = declaration.as(StructDeclSyntax.self) else {
      context.diagnose(Diagnostic(node: Syntax(declaration), message: SensitiveActionDiagnostic.onlyStructsSupported))
      return []
    }
    
    let conformsToAction = structDecl.inheritanceClause?.inheritedTypes.contains { inheritedType in
      let name = inheritedType.type.as(IdentifierTypeSyntax.self)?.name.text
      return name == "Action"
    } ?? false
    
    guard conformsToAction else {
      context.diagnose(Diagnostic(node: Syntax(node), message: SensitiveActionDiagnostic.mustConformToAction))
      return []
    }
    
    let structName = structDecl.name.text
    
    let fields = structDecl.memberBlock.members.compactMap {
      $0.decl.as(VariableDeclSyntax.self)
    }
    
    let isMaskedEnabled = self.isMaskedEnabled(node: node)
    let maskedFieldDescriptions = self.getFieldDescriptions(variables: fields, masked: isMaskedEnabled) ?? ""
    let plainFieldDescriptions = self.getFieldDescriptions(variables: fields, masked: false) ?? ""
    
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
      
    let shouldDisbaleMaskingFields = SensitiveActionOption(rawValue: option) == .disabledInDebug
    
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
        if sensitive && masked {
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
          accessors: .getter(CodeBlockItemListSyntax.init(itemsBuilder: {
            StmtSyntax(
              """
              return "\(raw: structName)(" + \(raw: fieldDescriptions) + ")"
              """
            )
          })),
        )
      )
    }
  }
}


public struct SensitiveFieldMacro: PeerMacro {
  public static func expansion(
    of node: AttributeSyntax,
    providingPeersOf declaration: some DeclSyntaxProtocol,
    in context: some MacroExpansionContext
  ) throws -> [DeclSyntax] { [] }
}
