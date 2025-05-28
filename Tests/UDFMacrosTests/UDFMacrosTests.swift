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
                case congratulations(Command)
                case analytics(Wish.ID)
                case addVideoFeedback(presentAddPhotoFeedback: Command)
                case addPhotoFeedback(wishId: Wish.ID)
                case additionalPhotosZoomed(selectedPhoto: S3MediaResource, photos: [S3MediaResource])
                case comments(presentation: WishDetailsPresentationType, wishId: Wish.ID)
                case wishmates(Wish.ID)
                case editWishFeedback(wishFeedback: WishFeedback)
                case boosts(Wish.ID)
            }
            """#,
            expandedSource: #"""
            enum TestEnum {
                case congratulations(Command)
                case analytics(Wish.ID)
                case addVideoFeedback(presentAddPhotoFeedback: Command)
                case addPhotoFeedback(wishId: Wish.ID)
                case additionalPhotosZoomed(selectedPhoto: S3MediaResource, photos: [S3MediaResource])
                case comments(presentation: WishDetailsPresentationType, wishId: Wish.ID)
                case wishmates(Wish.ID)
                case editWishFeedback(wishFeedback: WishFeedback)
                case boosts(Wish.ID)
            }

            extension TestEnum: Equatable {
                static func ==(lhs: Self, rhs: Self) -> Bool {
                    switch (lhs, rhs) {
                    case let (.congratulations(_), .congratulations(_)):
                        true
                    case let (.analytics(lhs0), .analytics(rhs0)):
                        lhs0 == rhs0
                    case let (.addVideoFeedback(_), .addVideoFeedback(_)):
                        true
                    case let (.addPhotoFeedback(lhs0), .addPhotoFeedback(rhs0)):
                        lhs0 == rhs0
                    case let (.additionalPhotosZoomed(lhs0, _), .additionalPhotosZoomed(rhs0, _)):
                        lhs0 == rhs0
                    case let (.comments(_, lhs1), .comments(_, rhs1)):
                        lhs1 == rhs1
                    case let (.wishmates(lhs0), .wishmates(rhs0)):
                        lhs0 == rhs0
                    case let (.editWishFeedback(_), .editWishFeedback(_)):
                        true
                    case let (.boosts(lhs0), .boosts(rhs0)):
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
            struct TestStruct {
                let id: Int
                let value: Int
                let model: Model
                let modelID: Model.ID
            }
            
            extension TestStruct: Equatable {
                static func ==(lhs: Self, rhs: Self) -> Bool {
                    lhs.id == rhs.id && lhs.value == rhs.value && lhs.modelID == rhs.modelID
                }
            }
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
            class TestClass {
                let id: Int
                let value: Int
                let model: Model
                let modelID: Model.ID
            }

            extension TestClass: Equatable {
                static func ==(lhs: Self, rhs: Self) -> Bool {
                    lhs.id == rhs.id && lhs.value == rhs.value && lhs.modelID == rhs.modelID
                }
            }
            """#,
            macros: testMacros
        )
        #else
        throw XCTSkip("macros are only supported when running tests for the host platform")
        #endif
    }
}
