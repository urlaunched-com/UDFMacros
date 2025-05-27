import SwiftCompilerPlugin
import SwiftSyntax
import SwiftSyntaxBuilder
import SwiftSyntaxMacros

public struct AutoEquatableMacro: ExtensionMacro {
    public static func expansion(
        of node: AttributeSyntax,
        attachedTo declaration: some DeclGroupSyntax,
        providingExtensionsOf type: some TypeSyntaxProtocol,
        conformingTo protocols: [TypeSyntax],
        in context: some MacroExpansionContext
    ) throws -> [ExtensionDeclSyntax] {
        guard let enumDecl = declaration.as(EnumDeclSyntax.self) else { return [] }
        
        let members = enumDecl.memberBlock.members
        let caseDecl = members.compactMap { $0.decl.as(EnumCaseDeclSyntax.self) }
        let elements = caseDecl.flatMap { $0.elements }
        
        let arms: String = elements.map { element in
            let caseName = element.name.text
            if let assoc = element.parameterClause, !assoc.parameters.isEmpty {
                let enumeratedParameters = assoc.parameters.enumerated()
                let lhsBindings = enumeratedParameters.map { index, param in
                    let typeName = param.type.description.trimmingCharacters(in: .whitespacesAndNewlines)
                    return typeName.isEquatableByName ? "lhs\(index)" : "_"
                }
                
                let rhsBindings = enumeratedParameters.map { index, param in
                    let typeName = param.type.description.trimmingCharacters(in: .whitespacesAndNewlines)
                    return typeName.isEquatableByName ? "rhs\(index)" : "_"
                }
                
                let lhsPattern = lhsBindings.joined(separator: ", ")
                let rhsPattern = rhsBindings.joined(separator: ", ")

                let comparisons = enumeratedParameters .compactMap { index, param in
                    let typeName = param.type.description.trimmingCharacters(in: .whitespacesAndNewlines)
                    
                    if typeName.isEquatableByName {
                        return "\(lhsBindings[index]) == \(rhsBindings[index])"
                    }
                    
                    return nil
                }
                
                let condition = comparisons.isEmpty ? "true" : comparisons.joined(separator: " && ")
                return "case let (.\(caseName)(\(lhsPattern)), .\(caseName)(\(rhsPattern))): \(condition)"
            } else {
                return "case (.\(caseName), .\(caseName)): true"
            }
        }.joined(separator: "\n")
        
        let ext: DeclSyntax =
              """
              extension \(type.trimmed): Equatable {
                  static func == (lhs: Self, rhs: Self) -> Bool {
                      switch (lhs, rhs) {
                      \(raw: arms)
                      default: false
                      }
                  }
              }
              """
        
        return [ext.cast(ExtensionDeclSyntax.self)]
    }
}

private extension String {
    var isEquatableByName: Bool {
        if hasSuffix(".ID") {
            return true
        }
        
        switch self {
        case "S3MediaResource", "Int", "String", "Bool", "Double", "Float":
            return true
        default:
            return false
        }
    }
}

@main
struct UDFMacrosPlugin: CompilerPlugin {
    let providingMacros: [Macro.Type] = [
        AutoEquatableMacro.self,
    ]
}
