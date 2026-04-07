import SwiftCompilerPlugin
import SwiftSyntax
import SwiftSyntaxBuilder
import SwiftSyntaxMacros

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
      return []
    }
    
    let structName = structDecl.name.text
    
    let fields = structDecl.memberBlock.members.compactMap {
      $0.decl.as(VariableDeclSyntax.self)
    }
    
    let maskedFieldDescriptions = self.getFieldDescriptions(variables: fields, masked: true) ?? ""
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
  
  private static func isSensitive(variable: VariableDeclSyntax) -> Bool {
    variable.attributes.contains {
      $0.as(AttributeSyntax.self)?
        .attributeName
        .as(IdentifierTypeSyntax.self)?
        .name.text == sensitiveAttributeName
    }
  }
  
  private static func getFieldDescriptions(variables: [VariableDeclSyntax], masked: Bool) -> String? {
    return variables.compactMap { variable -> String? in
      guard let name = variable.bindings.first?
        .pattern.as(IdentifierPatternSyntax.self)?
        .identifier.text
      else {
        return nil
      }
      
      if isSensitive(variable: variable) && masked {
        return #""\#(name): \(String(String(repeating: "*", count: self.\#(name).count)))""#
      } else {
        return #""\#(name): \(self.\#(name))""#
      }
    }.joined(separator: #" + ", " + "#)
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
