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
            return try equatableFor(vars: vars, type: type)
        } else if let classDecl = declaration.as(ClassDeclSyntax.self) {
            // Handle class: compare stored properties
            // Collect all variable declarations in the class
            let vars = classDecl.memberBlock.members.compactMap { $0.decl.as(VariableDeclSyntax.self) }
            return try equatableFor(vars: vars, type: type)
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
            let function = try FunctionDeclSyntax("static func ==(lhs: Self, rhs: Self) -> Bool") {
                StmtSyntax("switch (lhs, rhs) {")
                equatableArms
                StmtSyntax("default: false")
                StmtSyntax("}")
            }
            let ext: DeclSyntax =
            """
            extension \(type.trimmed): Equatable {
                \(raw: function.description)
            }
            """
            
            // Return the generated extension declaration to the compiler plugin
            return [ext.cast(ExtensionDeclSyntax.self)]
        } else {
            return []
        }
    }
}

/// TypeAnalyzer provides simplified type analysis using compiler-based verification.
/// 
/// This approach eliminates all hardcoded type checking and instead generates
/// equality comparisons for all types, letting the Swift compiler determine
/// if types are actually Equatable at compile time.
private struct TypeAnalyzer {
    /// Determines if a type should be included in equality comparison.
    ///
    /// This simplified approach attempts equality for all types except those
    /// explicitly known to be problematic, letting the compiler handle verification.
    ///
    /// - Parameter typeSyntax: The type syntax node to analyze
    /// - Returns: `true` if the type should be included in equality comparison
    static func shouldIncludeInEquality(_ typeSyntax: TypeSyntax) -> Bool {
        let typeDescription = typeSyntax.description.trimmingCharacters(in: .whitespacesAndNewlines)
        return shouldIncludeInEquality(typeDescription)
    }
    
    /// Determines if a type name should be included in equality comparison.
    ///
    /// - Parameter typeName: The type name string to analyze
    /// - Returns: `true` if the type should be included in equality comparison
    static func shouldIncludeInEquality(_ typeName: String) -> Bool {
        // Only exclude types that are definitively known to be problematic
        switch typeName {
        case "Void", "Never":
            return false
        default:
            // Check if this is a closure type (function type)
            if isClosureType(typeName) {
                return false
            }
            // For everything else: attempt equality and let the compiler decide
            return true
        }
    }
    
    /// Determines if a type string represents a closure/function type.
    ///
    /// - Parameter typeName: The type name string to analyze
    /// - Returns: `true` if the type is a closure/function type
    private static func isClosureType(_ typeName: String) -> Bool {
        let trimmed = typeName.trimmingCharacters(in: .whitespacesAndNewlines)
        
        // Remove @escaping, @autoclosure, etc. attributes
        let withoutAttributes = trimmed.replacingOccurrences(of: "@escaping ", with: "")
            .replacingOccurrences(of: "@autoclosure ", with: "")
            .replacingOccurrences(of: "@Sendable ", with: "")
            .trimmingCharacters(in: .whitespacesAndNewlines)
        
        // Check for function type syntax: contains -> with parentheses
        // Examples: () -> Void, (Int) -> String, (String, Int) -> Bool
        return withoutAttributes.contains("->") && 
               (withoutAttributes.hasPrefix("(") || withoutAttributes.contains("("))
    }
}

private extension ExtensionMacro {
    static func equatableFor(vars: [VariableDeclSyntax], type: some TypeSyntaxProtocol) throws -> [ExtensionDeclSyntax] {
        let properties: [(name: String, type: String)] = vars.flatMap { varDecl in
            varDecl.bindings.compactMap { binding in
                guard let pattern = binding.pattern.as(IdentifierPatternSyntax.self) else { return nil }
                let name = pattern.identifier.text
                let typeName = binding.typeAnnotation?.type.description
                    .trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
                return (name: name, type: typeName)
            }
        }
        // Build comparisons for all properties (let compiler verify Equatable conformance)
        let comparisons = properties.compactMap { prop in
            TypeAnalyzer.shouldIncludeInEquality(prop.type) ? "lhs.\(prop.name) == rhs.\(prop.name)" : nil
        }
        let body = comparisons.isEmpty ? "true" : comparisons.joined(separator: " && ")
        // Build the static == function using SwiftSyntaxBuilder
        let function = try FunctionDeclSyntax("static func ==(lhs: Self, rhs: Self) -> Bool") {
            StmtSyntax("\(raw: body)")
        }
        // Create the extension embedding the function
        let extDecl: DeclSyntax =
        """
        extension \(type.trimmed): Equatable {
            \(raw: function.description)
        }
        """
        return [extDecl.cast(ExtensionDeclSyntax.self)]
    }
    
    static func equatableArmsFor(enumElements: [EnumCaseElementListSyntax.Element]) -> [StmtSyntax] {
        // Build each switch arm for the `==` implementation
        enumElements.map { element in
            // Get the name of this enum case
            let caseName = element.name.text
            // If the case has associated values, generate bindings and comparisons
            if let assoc = element.parameterClause, !assoc.parameters.isEmpty {
                // Enumerate associated parameters for indexing
                let enumeratedParameters = assoc.parameters.enumerated()
                // Generate binding identifiers for all values (let compiler verify Equatable conformance)
                let lhsBindings = enumeratedParameters.map { index, param in
                    let typeName = param.type.description.trimmingCharacters(in: .whitespacesAndNewlines)
                    return TypeAnalyzer.shouldIncludeInEquality(typeName) ? "lhs\(index)" : "_"
                }
                
                // Generate binding identifiers for rhs values similarly
                let rhsBindings = enumeratedParameters.map { index, param in
                    let typeName = param.type.description.trimmingCharacters(in: .whitespacesAndNewlines)
                    return TypeAnalyzer.shouldIncludeInEquality(typeName) ? "rhs\(index)" : "_"
                }
                
                // Create the tuple pattern for lhs bindings
                let lhsPattern = lhsBindings.joined(separator: ", ")
                // Create the tuple pattern for rhs bindings
                let rhsPattern = rhsBindings.joined(separator: ", ")

                // Build comparison expressions for all associated values (let compiler verify Equatable conformance)
                let comparisons = enumeratedParameters.compactMap { index, param in
                    let typeName = param.type.description.trimmingCharacters(in: .whitespacesAndNewlines)
                    
                    if TypeAnalyzer.shouldIncludeInEquality(typeName) {
                        return "\(lhsBindings[index]) == \(rhsBindings[index])"
                    }
                    
                    return nil
                }
                
                // Determine the overall condition: true if no comparisons, else join with &&
                let condition = comparisons.isEmpty ? "true" : comparisons.joined(separator: " && ")
                // Return this switch arm for the case with its comparison logic
                return StmtSyntax(stringLiteral: "case let (.\(caseName)(\(lhsPattern)), .\(caseName)(\(rhsPattern))): \(condition)\n")
            } else {
                // No associated values: same-case implies equality
                return StmtSyntax(stringLiteral: "case (.\(caseName), .\(caseName)): true\n")
            }
        }
    }
}


@main
struct UDFMacrosPlugin: CompilerPlugin {
    let providingMacros: [Macro.Type] = [
        AutoEquatableMacro.self,
    ]
}
