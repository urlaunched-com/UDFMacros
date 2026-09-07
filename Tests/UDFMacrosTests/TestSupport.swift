import SwiftSyntaxMacros

// Macro implementations build for the host, so the corresponding module is not available when cross-compiling. Cross-compiled tests may still make use of the macro itself in end-to-end tests.
#if canImport(UDFMacrosMacros)
    import UDFMacrosMacros

    let testMacros: [String: Macro.Type] = [
        "AutoEquatable": AutoEquatableMacro.self,
        "AutoHashable": AutoHashableMacro.self,
        "Storage": StorageMacro.self,
        "StorageRelationships": StorageRelationshipsMacro.self,
    ]
#endif
