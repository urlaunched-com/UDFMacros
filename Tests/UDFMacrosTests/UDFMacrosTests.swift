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
    "AutoHashable": AutoHashableMacro.self,
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
                static func ==(lhs: TestStruct, rhs: TestStruct) -> Bool {
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
                static func ==(lhs: TestClass, rhs: TestClass) -> Bool {
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
    
    func testAutoHashableForEnum() throws {
        #if canImport(UDFMacrosMacros)
        assertMacroExpansion(
            #"""
            @AutoHashable enum TestEnum {
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

            extension TestEnum: Hashable {
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

                func hash(into hasher: inout Hasher) {
                    switch self {
                    case let .analytics(value0):
                        hasher.combine(value0)
                    case let .addPhotoFeedback(value0):
                        hasher.combine(value0)
                    case let .additionalPhotosZoomed(value0, _):
                        hasher.combine(value0)
                    case let .comments(_, value1):
                        hasher.combine(value1)
                    case let .wishmates(value0):
                        hasher.combine(value0)
                    case let .boosts(value0):
                        hasher.combine(value0)
                    default:
                        hasher.combine(hashValue)
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
    
    func testAutoHashableForStruct() throws {
        #if canImport(UDFMacrosMacros)
        assertMacroExpansion(
            #"""
            @AutoHashable struct TestStruct {
                private let id: Int
                let value: Int
                let model: Model
                let modelID: Model.ID
            }
            """#,
            expandedSource: #"""
            struct TestStruct {
                private let id: Int
                let value: Int
                let model: Model
                let modelID: Model.ID
            }
            
            extension TestStruct: Hashable {
                static func ==(lhs: TestStruct, rhs: TestStruct) -> Bool {
                    lhs.id == rhs.id && lhs.value == rhs.value && lhs.modelID == rhs.modelID
                }
            
                func hash(into hasher: inout Hasher) {
                    hasher.combine(id)
                    hasher.combine(value)
                    hasher.combine(modelID)
                }
            }
            """#,
            macros: testMacros
        )
        #else
        throw XCTSkip("macros are only supported when running tests for the host platform")
        #endif
    }
    
    func testAutoHashableForClass() throws {
        #if canImport(UDFMacrosMacros)
        assertMacroExpansion(
            #"""
            @AutoHashable class TestClass {
                private let id: Int
                let value: Int
                let model: Model
                let modelID: Model.ID
            }
            """#,
            expandedSource: #"""
            class TestClass {
                private let id: Int
                let value: Int
                let model: Model
                let modelID: Model.ID
            }
            
            extension TestClass: Hashable {
                static func ==(lhs: TestClass, rhs: TestClass) -> Bool {
                    lhs.id == rhs.id && lhs.value == rhs.value && lhs.modelID == rhs.modelID
                }
            
                func hash(into hasher: inout Hasher) {
                    hasher.combine(id)
                    hasher.combine(value)
                    hasher.combine(modelID)
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
