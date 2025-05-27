import SwiftSyntax
import SwiftSyntaxBuilder
import SwiftSyntaxMacros
import SwiftSyntaxMacrosTestSupport
import XCTest

// Macro implementations build for the host, so the corresponding module is not available when cross-compiling. Cross-compiled tests may still make use of the macro itself in end-to-end tests.
#if canImport(UDFMacrosMacros)
import UDFMacrosMacros

let testMacros: [String: Macro.Type] = [
    "AutoEquatable": AutoEquatableMacro.self,
]
#endif

final class UDFMacrosTests: XCTestCase {
    func testAutoEquatableMacro() throws {
        #if canImport(UDFMacrosMacros)
        assertMacroExpansion(
            #"""
            @AutoEquatable enum TestEnum {
                case test1(id: Int, index: Int)
                case test2(Int)
                case test3(flag: Bool, modelID: Model.ID, user: User)
                case test4
                case test5(Model.ID)
            }
            """#,
            expandedSource: #"""
            ""
            """#,
            macros: testMacros
        )
        #else
        throw XCTSkip("macros are only supported when running tests for the host platform")
        #endif
    }
}
