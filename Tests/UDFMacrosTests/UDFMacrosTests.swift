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
    func testAutoEquatableForEnum() throws {
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
            enum TestEnum {
                case test1(id: Int, index: Int)
                case test2(Int)
                case test3(flag: Bool, modelID: Model.ID, user: User)
                case test4
                case test5(Model.ID)
            }

            extension TestEnum: Equatable {
                static func == (lhs: Self, rhs: Self) -> Bool {
                    switch (lhs, rhs) {
                    case let (.test1(lhs0, lhs1), .test1(rhs0, rhs1)):
                        lhs0 == rhs0 && lhs1 == rhs1
                    case let (.test2(lhs0), .test2(rhs0)):
                        lhs0 == rhs0
                    case let (.test3(lhs0, lhs1, _), .test3(rhs0, rhs1, _)):
                        lhs0 == rhs0 && lhs1 == rhs1
                    case (.test4, .test4):
                        true
                    case let (.test5(lhs0), .test5(rhs0)):
                        lhs0 == rhs0
                    default:
                        false
                    }
                }
            }
            """#,
            macros: testMacros
        )
        #else
        throw XCTSkip("macros are only supported when running tests for the host platform")
        #endif
    }
    
    func testAutoEquatableForStruct() throws {
        #if canImport(UDFMacrosMacros)
        assertMacroExpansion(
            #"""
            @AutoEquatable struct TestStruct {
                let id: Int
                let value: Int
                let model: Model
                let modelID: Model.ID
            }
            """#,
            expandedSource: #"""
            """#,
            macros: testMacros
        )
        #else
        throw XCTSkip("macros are only supported when running tests for the host platform")
        #endif
    }
    
    func testAutoEquatableForClass() throws {
        #if canImport(UDFMacrosMacros)
        assertMacroExpansion(
            #"""
            @AutoEquatable class TestClass {
                let id: Int
                let value: Int
                let model: Model
                let modelID: Model.ID
            }
            """#,
            expandedSource: #"""
            """#,
            macros: testMacros
        )
        #else
        throw XCTSkip("macros are only supported when running tests for the host platform")
        #endif
    }
}
