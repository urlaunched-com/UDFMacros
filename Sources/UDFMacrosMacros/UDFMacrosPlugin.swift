import SwiftCompilerPlugin
import SwiftSyntax
import SwiftSyntaxBuilder
import SwiftSyntaxMacros

@main
struct UDFMacrosPlugin: CompilerPlugin {
    let providingMacros: [Macro.Type] = [
        AutoEquatableMacro.self,
        AutoHashableMacro.self,
        SensitiveFieldMacro.self,
        SensitiveDataMacro.self,
        StorageMacro.self,
        StorageRelationshipsMacro.self,
    ]
}
