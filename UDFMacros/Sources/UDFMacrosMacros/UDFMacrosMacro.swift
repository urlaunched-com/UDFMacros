import SwiftCompilerPlugin
import SwiftSyntax
import SwiftSyntaxBuilder
import SwiftSyntaxMacros

/// A macro that generates a custom Equatable extension for enums,
/// comparing only those associated values whose types are Equatable by name.
///
/// The macro inspects each enum case and synthesizes a `==` implementation
/// in an `extension <Enum>: Equatable` block.
public struct AutoEquatableMacro: ExtensionMacro {
    /// Synthesizes an Equatable conformance for the attached enum.
    ///
    /// - Parameters:
    ///   - node: The `@AutoEquatable` attribute syntax node.
    ///   - attachedTo: The declaration to which the attribute is attached (must be an enum).
    ///   - providingExtensionsOf: The type to extend (the enum identifier).
    ///   - conformingTo: Unused in this macro (always `Equatable`).
    ///   - context: Contextual information for macro expansion.
    ///
    /// - Returns: An array containing a single `ExtensionDeclSyntax`
    ///   which implements the `static func ==` operator for the enum.
    public static func expansion(
        of node: AttributeSyntax,
        attachedTo declaration: some DeclGroupSyntax,
        providingExtensionsOf type: some TypeSyntaxProtocol,
        conformingTo protocols: [TypeSyntax],
        in context: some MacroExpansionContext
    ) throws -> [ExtensionDeclSyntax] {
        // Ensure we're attached to an enum; otherwise, nothing to generate
        if let structDecl = declaration.as(StructDeclSyntax.self) {
            // Handle struct: compare stored properties
            // Collect all variable declarations in the struct
            let vars = structDecl.memberBlock.members.compactMap { $0.decl.as(VariableDeclSyntax.self) }
            return equatableFor(vars: vars, type: type)
        } else if let classDecl = declaration.as(ClassDeclSyntax.self) {
            // Handle class: compare stored properties
            // Collect all variable declarations in the class
            let vars = classDecl.memberBlock.members.compactMap { $0.decl.as(VariableDeclSyntax.self) }
            return equatableFor(vars: vars, type: type)
        } else if let enumDecl = declaration.as(EnumDeclSyntax.self) {
            // Collect all member declarations of the enum
            let members = enumDecl.memberBlock.members
            // Filter members to only enum case declarations
            let caseDecl = members.compactMap { $0.decl.as(EnumCaseDeclSyntax.self) }
            // Flatten the cases to get all individual enum elements
            let elements = caseDecl.flatMap { $0.elements }
            
            // Build each switch arm for the `==` implementation
            let equatableArms = equatableArmsFor(enumElements: elements)
            
            // Construct the Equatable extension for the enum
            let ext: DeclSyntax =
                  """
                  extension \(type.trimmed): Equatable {
                      static func == (lhs: Self, rhs: Self) -> Bool {
                          switch (lhs, rhs) {
                          \(raw: equatableArms)
                          default: false
                          }
                      }
                  }
                  """
            
            // Return the generated extension declaration to the compiler plugin
            return [ext.cast(ExtensionDeclSyntax.self)]
        } else {
            return []
        }
    }
}

/// String utilities to determine if a type name should be treated as Equatable.
private extension String {
    /// Checks if the string (type name) indicates Equatable conformance by name.
    ///
    /// Returns `true` if the type name has a `.ID` suffix, is `S3MediaResource`,
    /// or is one of the known Equatable primitives (`Int`, `String`, etc.).
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

private extension ExtensionMacro {
    static func equatableFor(vars: [VariableDeclSyntax], type: some TypeSyntaxProtocol) -> [ExtensionDeclSyntax] {
        let properties: [(name: String, type: String)] = vars.flatMap { varDecl in
            varDecl.bindings.compactMap { binding in
                guard let pattern = binding.pattern.as(IdentifierPatternSyntax.self) else { return nil }
                let name = pattern.identifier.text
                let typeName = binding.typeAnnotation?.type.description
                    .trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
                return (name: name, type: typeName)
            }
        }
        // Build comparisons for Equatable properties
        let comparisons = properties.compactMap { prop in
            prop.type.isEquatableByName ? "lhs.\(prop.name) == rhs.\(prop.name)" : nil
        }
        let body = comparisons.isEmpty ? "true" : comparisons.joined(separator: " && ")
        // Generate extension
        let ext: DeclSyntax =
        """
        extension \(type.trimmed): Equatable {
            static func ==(lhs: Self, rhs: Self) -> Bool {
                \(raw: body)
            }
        }
        """
        return [ext.cast(ExtensionDeclSyntax.self)]
    }
    
    static func equatableArmsFor(enumElements: [EnumCaseElementListSyntax.Element]) -> String {
        // Build each switch arm for the `==` implementation
        enumElements.map { element in
            // Get the name of this enum case
            let caseName = element.name.text
            // If the case has associated values, generate bindings and comparisons
            if let assoc = element.parameterClause, !assoc.parameters.isEmpty {
                // Enumerate associated parameters for indexing
                let enumeratedParameters = assoc.parameters.enumerated()
                // Generate binding identifiers for lhs values where type is Equatable
                let lhsBindings = enumeratedParameters.map { index, param in
                    let typeName = param.type.description.trimmingCharacters(in: .whitespacesAndNewlines)
                    return typeName.isEquatableByName ? "lhs\(index)" : "_"
                }
                
                // Generate binding identifiers for rhs values similarly
                let rhsBindings = enumeratedParameters.map { index, param in
                    let typeName = param.type.description.trimmingCharacters(in: .whitespacesAndNewlines)
                    return typeName.isEquatableByName ? "rhs\(index)" : "_"
                }
                
                // Create the tuple pattern for lhs bindings
                let lhsPattern = lhsBindings.joined(separator: ", ")
                // Create the tuple pattern for rhs bindings
                let rhsPattern = rhsBindings.joined(separator: ", ")

                // Build comparison expressions for each Equatable associated value
                let comparisons = enumeratedParameters.compactMap { index, param in
                    let typeName = param.type.description.trimmingCharacters(in: .whitespacesAndNewlines)
                    
                    if typeName.isEquatableByName {
                        return "\(lhsBindings[index]) == \(rhsBindings[index])"
                    }
                    
                    return nil
                }
                
                // Determine the overall condition: true if no comparisons, else join with &&
                let condition = comparisons.isEmpty ? "true" : comparisons.joined(separator: " && ")
                // Return this switch arm for the case with its comparison logic
                return "case let (.\(caseName)(\(lhsPattern)), .\(caseName)(\(rhsPattern))): \(condition)"
            } else {
                // No associated values: same-case implies equality
                return "case (.\(caseName), .\(caseName)): true"
            }
        }.joined(separator: "\n")
    }
}


@main
struct UDFMacrosPlugin: CompilerPlugin {
    let providingMacros: [Macro.Type] = [
        AutoEquatableMacro.self,
    ]
}
