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
        "Storage": StorageMacro.self,
        "StorageRelationships": StorageRelationshipsMacro.self,
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
                    static func ==(lhs: TestEnum, rhs: TestEnum) -> Bool {
                        switch (lhs, rhs) {
                        case let (.congratulations(_), .congratulations(_)):
                            true
                        case let (.analytics(lhs0), .analytics(rhs0)):
                            lhs0 == rhs0
                        case let (.addVideoFeedback(_), .addVideoFeedback(_)):
                            true
                        case let (.addPhotoFeedback(lhs0), .addPhotoFeedback(rhs0)):
                            lhs0 == rhs0
                        case let (.additionalPhotosZoomed(lhs0, lhs1), .additionalPhotosZoomed(rhs0, rhs1)):
                            lhs0 == rhs0 && lhs1 == rhs1
                        case let (.comments(lhs0, lhs1), .comments(rhs0, rhs1)):
                            lhs0 == rhs0 && lhs1 == rhs1
                        case let (.wishmates(lhs0), .wishmates(rhs0)):
                            lhs0 == rhs0
                        case let (.editWishFeedback(lhs0), .editWishFeedback(rhs0)):
                            lhs0 == rhs0
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
                        lhs.id == rhs.id && lhs.value == rhs.value && lhs.model == rhs.model && lhs.modelID == rhs.modelID
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
                        lhs.id == rhs.id && lhs.value == rhs.value && lhs.model == rhs.model && lhs.modelID == rhs.modelID
                    }
                }
                """#,
                macros: testMacros
            )
        #else
            throw XCTSkip("macros are only supported when running tests for the host platform")
        #endif
    }

    func testAutoEquatableForStructWithArraysAndOptionals() throws {
        #if canImport(UDFMacrosMacros)
            assertMacroExpansion(
                #"""
                @AutoEquatable struct TestStruct {
                    let ids: [Int]
                    let names: [String]
                    let optionalId: Int?
                    let optionalName: String?
                    let resources: [S3MediaResource]
                    let nonEquatableArray: [Command]
                    let uuid: UUID
                    let date: Date
                }
                """#,
                expandedSource: #"""
                struct TestStruct {
                    let ids: [Int]
                    let names: [String]
                    let optionalId: Int?
                    let optionalName: String?
                    let resources: [S3MediaResource]
                    let nonEquatableArray: [Command]
                    let uuid: UUID
                    let date: Date
                }

                extension TestStruct: Equatable {
                    static func ==(lhs: TestStruct, rhs: TestStruct) -> Bool {
                        lhs.ids == rhs.ids && lhs.names == rhs.names && lhs.optionalId == rhs.optionalId && lhs.optionalName == rhs.optionalName && lhs.resources == rhs.resources && lhs.nonEquatableArray == rhs.nonEquatableArray && lhs.uuid == rhs.uuid && lhs.date == rhs.date
                    }
                }
                """#,
                macros: testMacros
            )
        #else
            throw XCTSkip("macros are only supported when running tests for the host platform")
        #endif
    }

    func testAutoEquatableForStructWithCollections() throws {
        #if canImport(UDFMacrosMacros)
            assertMacroExpansion(
                #"""
                @AutoEquatable struct TestStruct {
                    let stringSet: Set<String>
                    let intDict: Dictionary<String, Int>
                    let tuple: (Int, String, Bool)
                    let nonEquatableTuple: (Command, String)
                }
                """#,
                expandedSource: #"""
                struct TestStruct {
                    let stringSet: Set<String>
                    let intDict: Dictionary<String, Int>
                    let tuple: (Int, String, Bool)
                    let nonEquatableTuple: (Command, String)
                }

                extension TestStruct: Equatable {
                    static func ==(lhs: TestStruct, rhs: TestStruct) -> Bool {
                        lhs.stringSet == rhs.stringSet && lhs.intDict == rhs.intDict && lhs.tuple == rhs.tuple && lhs.nonEquatableTuple == rhs.nonEquatableTuple
                    }
                }
                """#,
                macros: testMacros
            )
        #else
            throw XCTSkip("macros are only supported when running tests for the host platform")
        #endif
    }

    func testAutoEquatableForEnumWithMixedTypes() throws {
        #if canImport(UDFMacrosMacros)
            assertMacroExpansion(
                #"""
                @AutoEquatable enum TestEnum {
                    case withArrays(ids: [Int], names: [String])
                    case withOptionals(id: Int?, name: String?)
                    case withSets(numbers: Set<Int>, strings: Set<String>)
                    case withDictionary(mapping: Dictionary<String, Int>)
                    case withTuple(data: (Int, String, Bool))
                    case withMixed(id: Int, command: Command, resources: [S3MediaResource])
                    case withUUID(uuid: UUID, date: Date)
                }
                """#,
                expandedSource: #"""
                enum TestEnum {
                    case withArrays(ids: [Int], names: [String])
                    case withOptionals(id: Int?, name: String?)
                    case withSets(numbers: Set<Int>, strings: Set<String>)
                    case withDictionary(mapping: Dictionary<String, Int>)
                    case withTuple(data: (Int, String, Bool))
                    case withMixed(id: Int, command: Command, resources: [S3MediaResource])
                    case withUUID(uuid: UUID, date: Date)
                }

                extension TestEnum: Equatable {
                    static func ==(lhs: TestEnum, rhs: TestEnum) -> Bool {
                        switch (lhs, rhs) {
                        case let (.withArrays(lhs0, lhs1), .withArrays(rhs0, rhs1)):
                            lhs0 == rhs0 && lhs1 == rhs1
                        case let (.withOptionals(lhs0, lhs1), .withOptionals(rhs0, rhs1)):
                            lhs0 == rhs0 && lhs1 == rhs1
                        case let (.withSets(lhs0, lhs1), .withSets(rhs0, rhs1)):
                            lhs0 == rhs0 && lhs1 == rhs1
                        case let (.withDictionary(lhs0), .withDictionary(rhs0)):
                            lhs0 == rhs0
                        case let (.withTuple(lhs0), .withTuple(rhs0)):
                            lhs0 == rhs0
                        case let (.withMixed(lhs0, _, lhs2), .withMixed(rhs0, _, rhs2)):
                            lhs0 == rhs0 && lhs2 == rhs2
                        case let (.withUUID(lhs0, lhs1), .withUUID(rhs0, rhs1)):
                            lhs0 == rhs0 && lhs1 == rhs1
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

    func testAutoEquatableForEnumWithCustomTypes() throws {
        #if canImport(UDFMacrosMacros)
            assertMacroExpansion(
                #"""
                @AutoEquatable enum MyCustomEnum {
                    case withPrimitives(id: Int, name: String, active: Bool)
                    case withCustomStruct(data: MyCustomStruct)
                    case withMixed(id: Int, struct: MyCustomStruct, count: Int)
                    case withArray(items: [MyCustomStruct])
                    case withOptional(item: MyCustomStruct?)
                    case noAssociatedValues
                }
                """#,
                expandedSource: #"""
                enum MyCustomEnum {
                    case withPrimitives(id: Int, name: String, active: Bool)
                    case withCustomStruct(data: MyCustomStruct)
                    case withMixed(id: Int, struct: MyCustomStruct, count: Int)
                    case withArray(items: [MyCustomStruct])
                    case withOptional(item: MyCustomStruct?)
                    case noAssociatedValues
                }

                extension MyCustomEnum: Equatable {
                    static func ==(lhs: MyCustomEnum, rhs: MyCustomEnum) -> Bool {
                        switch (lhs, rhs) {
                        case let (.withPrimitives(lhs0, lhs1, lhs2), .withPrimitives(rhs0, rhs1, rhs2)):
                            lhs0 == rhs0 && lhs1 == rhs1 && lhs2 == rhs2
                        case let (.withCustomStruct(lhs0), .withCustomStruct(rhs0)):
                            lhs0 == rhs0
                        case let (.withMixed(lhs0, lhs1, lhs2), .withMixed(rhs0, rhs1, rhs2)):
                            lhs0 == rhs0 && lhs1 == rhs1 && lhs2 == rhs2
                        case let (.withArray(lhs0), .withArray(rhs0)):
                            lhs0 == rhs0
                        case let (.withOptional(lhs0), .withOptional(rhs0)):
                            lhs0 == rhs0
                        case (.noAssociatedValues, .noAssociatedValues):
                            true
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

    func testAutoEquatableWithSimplifiedApproach() throws {
        #if canImport(UDFMacrosMacros)
            // Test that the simplified approach generates comparisons for ALL types
            // without any hardcoded type checking
            assertMacroExpansion(
                #"""
                @AutoEquatable enum TestEnum {
                    case withUnknownType(CustomType)
                    case withAnotherUnknownType(SomeOtherType)
                    case withComplexNested([[[CustomType]]])
                    case withTuple((CustomType, AnotherType, ThirdType))
                    case withOptional(CustomType?)
                    case withSet(Set<CustomType>)
                    case withDictionary(Dictionary<CustomType, AnotherType>)
                }
                """#,
                expandedSource: #"""
                enum TestEnum {
                    case withUnknownType(CustomType)
                    case withAnotherUnknownType(SomeOtherType)
                    case withComplexNested([[[CustomType]]])
                    case withTuple((CustomType, AnotherType, ThirdType))
                    case withOptional(CustomType?)
                    case withSet(Set<CustomType>)
                    case withDictionary(Dictionary<CustomType, AnotherType>)
                }

                extension TestEnum: Equatable {
                    static func ==(lhs: TestEnum, rhs: TestEnum) -> Bool {
                        switch (lhs, rhs) {
                        case let (.withUnknownType(lhs0), .withUnknownType(rhs0)):
                            lhs0 == rhs0
                        case let (.withAnotherUnknownType(lhs0), .withAnotherUnknownType(rhs0)):
                            lhs0 == rhs0
                        case let (.withComplexNested(lhs0), .withComplexNested(rhs0)):
                            lhs0 == rhs0
                        case let (.withTuple(lhs0), .withTuple(rhs0)):
                            lhs0 == rhs0
                        case let (.withOptional(lhs0), .withOptional(rhs0)):
                            lhs0 == rhs0
                        case let (.withSet(lhs0), .withSet(rhs0)):
                            lhs0 == rhs0
                        case let (.withDictionary(lhs0), .withDictionary(rhs0)):
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

    func testAutoEquatableForEnumWithNoAssociatedValues() throws {
        #if canImport(UDFMacrosMacros)
            assertMacroExpansion(
                #"""
                @AutoEquatable enum SimpleEnum {
                    case first
                    case second
                    case third
                }
                """#,
                expandedSource: #"""
                enum SimpleEnum {
                    case first
                    case second
                    case third
                }

                extension SimpleEnum: Equatable {
                    static func ==(lhs: SimpleEnum, rhs: SimpleEnum) -> Bool {
                        switch (lhs, rhs) {
                        case (.first, .first):
                            true
                        case (.second, .second):
                            true
                        case (.third, .third):
                            true
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

    func testAutoEquatableForEnumWithAllPrimitiveTypes() throws {
        #if canImport(UDFMacrosMacros)
            assertMacroExpansion(
                #"""
                @AutoEquatable enum PrimitiveEnum {
                    case withInt(Int)
                    case withString(String)
                    case withBool(Bool)
                    case withDouble(Double)
                    case withFloat(Float)
                    case withCharacter(Character)
                    case withInt8(Int8)
                    case withInt16(Int16)
                    case withInt32(Int32)
                    case withInt64(Int64)
                    case withUInt(UInt)
                    case withUInt8(UInt8)
                    case withUInt16(UInt16)
                    case withUInt32(UInt32)
                    case withUInt64(UInt64)
                }
                """#,
                expandedSource: #"""
                enum PrimitiveEnum {
                    case withInt(Int)
                    case withString(String)
                    case withBool(Bool)
                    case withDouble(Double)
                    case withFloat(Float)
                    case withCharacter(Character)
                    case withInt8(Int8)
                    case withInt16(Int16)
                    case withInt32(Int32)
                    case withInt64(Int64)
                    case withUInt(UInt)
                    case withUInt8(UInt8)
                    case withUInt16(UInt16)
                    case withUInt32(UInt32)
                    case withUInt64(UInt64)
                }

                extension PrimitiveEnum: Equatable {
                    static func ==(lhs: PrimitiveEnum, rhs: PrimitiveEnum) -> Bool {
                        switch (lhs, rhs) {
                        case let (.withInt(lhs0), .withInt(rhs0)):
                            lhs0 == rhs0
                        case let (.withString(lhs0), .withString(rhs0)):
                            lhs0 == rhs0
                        case let (.withBool(lhs0), .withBool(rhs0)):
                            lhs0 == rhs0
                        case let (.withDouble(lhs0), .withDouble(rhs0)):
                            lhs0 == rhs0
                        case let (.withFloat(lhs0), .withFloat(rhs0)):
                            lhs0 == rhs0
                        case let (.withCharacter(lhs0), .withCharacter(rhs0)):
                            lhs0 == rhs0
                        case let (.withInt8(lhs0), .withInt8(rhs0)):
                            lhs0 == rhs0
                        case let (.withInt16(lhs0), .withInt16(rhs0)):
                            lhs0 == rhs0
                        case let (.withInt32(lhs0), .withInt32(rhs0)):
                            lhs0 == rhs0
                        case let (.withInt64(lhs0), .withInt64(rhs0)):
                            lhs0 == rhs0
                        case let (.withUInt(lhs0), .withUInt(rhs0)):
                            lhs0 == rhs0
                        case let (.withUInt8(lhs0), .withUInt8(rhs0)):
                            lhs0 == rhs0
                        case let (.withUInt16(lhs0), .withUInt16(rhs0)):
                            lhs0 == rhs0
                        case let (.withUInt32(lhs0), .withUInt32(rhs0)):
                            lhs0 == rhs0
                        case let (.withUInt64(lhs0), .withUInt64(rhs0)):
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

    func testAutoEquatableForEnumWithLabeledAssociatedValues() throws {
        #if canImport(UDFMacrosMacros)
            assertMacroExpansion(
                #"""
                @AutoEquatable enum LabeledEnum {
                    case withSingleLabel(userId: Int)
                    case withMultipleLabels(userId: Int, name: String, active: Bool)
                    case withMixedLabels(Int, name: String, active: Bool)
                    case withComplexLabels(primaryId: UUID, secondaryIds: [Int], metadata: [String: String])
                }
                """#,
                expandedSource: #"""
                enum LabeledEnum {
                    case withSingleLabel(userId: Int)
                    case withMultipleLabels(userId: Int, name: String, active: Bool)
                    case withMixedLabels(Int, name: String, active: Bool)
                    case withComplexLabels(primaryId: UUID, secondaryIds: [Int], metadata: [String: String])
                }

                extension LabeledEnum: Equatable {
                    static func ==(lhs: LabeledEnum, rhs: LabeledEnum) -> Bool {
                        switch (lhs, rhs) {
                        case let (.withSingleLabel(lhs0), .withSingleLabel(rhs0)):
                            lhs0 == rhs0
                        case let (.withMultipleLabels(lhs0, lhs1, lhs2), .withMultipleLabels(rhs0, rhs1, rhs2)):
                            lhs0 == rhs0 && lhs1 == rhs1 && lhs2 == rhs2
                        case let (.withMixedLabels(lhs0, lhs1, lhs2), .withMixedLabels(rhs0, rhs1, rhs2)):
                            lhs0 == rhs0 && lhs1 == rhs1 && lhs2 == rhs2
                        case let (.withComplexLabels(lhs0, lhs1, lhs2), .withComplexLabels(rhs0, rhs1, rhs2)):
                            lhs0 == rhs0 && lhs1 == rhs1 && lhs2 == rhs2
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

    func testAutoEquatableForEnumWithNestedCollections() throws {
        #if canImport(UDFMacrosMacros)
            assertMacroExpansion(
                #"""
                @AutoEquatable enum NestedEnum {
                    case withNestedArrays([[Int]])
                    case withTripleNested([[[String]]])
                    case withNestedOptionals([Int?])
                    case withOptionalArrays([Int]?)
                    case withNestedSets(Set<Set<String>>)
                    case withNestedDictionaries([String: [Int: String]])
                    case withComplexNested([String: [Set<Int>]])
                }
                """#,
                expandedSource: #"""
                enum NestedEnum {
                    case withNestedArrays([[Int]])
                    case withTripleNested([[[String]]])
                    case withNestedOptionals([Int?])
                    case withOptionalArrays([Int]?)
                    case withNestedSets(Set<Set<String>>)
                    case withNestedDictionaries([String: [Int: String]])
                    case withComplexNested([String: [Set<Int>]])
                }

                extension NestedEnum: Equatable {
                    static func ==(lhs: NestedEnum, rhs: NestedEnum) -> Bool {
                        switch (lhs, rhs) {
                        case let (.withNestedArrays(lhs0), .withNestedArrays(rhs0)):
                            lhs0 == rhs0
                        case let (.withTripleNested(lhs0), .withTripleNested(rhs0)):
                            lhs0 == rhs0
                        case let (.withNestedOptionals(lhs0), .withNestedOptionals(rhs0)):
                            lhs0 == rhs0
                        case let (.withOptionalArrays(lhs0), .withOptionalArrays(rhs0)):
                            lhs0 == rhs0
                        case let (.withNestedSets(lhs0), .withNestedSets(rhs0)):
                            lhs0 == rhs0
                        case let (.withNestedDictionaries(lhs0), .withNestedDictionaries(rhs0)):
                            lhs0 == rhs0
                        case let (.withComplexNested(lhs0), .withComplexNested(rhs0)):
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

    func testAutoEquatableForEnumWithFoundationTypes() throws {
        #if canImport(UDFMacrosMacros)
            assertMacroExpansion(
                #"""
                @AutoEquatable enum FoundationEnum {
                    case withUUID(UUID)
                    case withDate(Date)
                    case withURL(URL)
                    case withData(Data)
                    case withDecimal(Decimal)
                    case withFoundationMix(uuid: UUID, date: Date, url: URL)
                }
                """#,
                expandedSource: #"""
                enum FoundationEnum {
                    case withUUID(UUID)
                    case withDate(Date)
                    case withURL(URL)
                    case withData(Data)
                    case withDecimal(Decimal)
                    case withFoundationMix(uuid: UUID, date: Date, url: URL)
                }

                extension FoundationEnum: Equatable {
                    static func ==(lhs: FoundationEnum, rhs: FoundationEnum) -> Bool {
                        switch (lhs, rhs) {
                        case let (.withUUID(lhs0), .withUUID(rhs0)):
                            lhs0 == rhs0
                        case let (.withDate(lhs0), .withDate(rhs0)):
                            lhs0 == rhs0
                        case let (.withURL(lhs0), .withURL(rhs0)):
                            lhs0 == rhs0
                        case let (.withData(lhs0), .withData(rhs0)):
                            lhs0 == rhs0
                        case let (.withDecimal(lhs0), .withDecimal(rhs0)):
                            lhs0 == rhs0
                        case let (.withFoundationMix(lhs0, lhs1, lhs2), .withFoundationMix(rhs0, rhs1, rhs2)):
                            lhs0 == rhs0 && lhs1 == rhs1 && lhs2 == rhs2
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

    func testAutoEquatableForEnumWithLongTuples() throws {
        #if canImport(UDFMacrosMacros)
            assertMacroExpansion(
                #"""
                @AutoEquatable enum TupleEnum {
                    case withTuple2((Int, String))
                    case withTuple3((Int, String, Bool))
                    case withTuple5((Int, String, Bool, Double, Float))
                    case withTuple10((Int, String, Bool, Double, Float, Character, Int8, Int16, Int32, Int64))
                    case withCustomTuple((UUID, Date, CustomType))
                }
                """#,
                expandedSource: #"""
                enum TupleEnum {
                    case withTuple2((Int, String))
                    case withTuple3((Int, String, Bool))
                    case withTuple5((Int, String, Bool, Double, Float))
                    case withTuple10((Int, String, Bool, Double, Float, Character, Int8, Int16, Int32, Int64))
                    case withCustomTuple((UUID, Date, CustomType))
                }

                extension TupleEnum: Equatable {
                    static func ==(lhs: TupleEnum, rhs: TupleEnum) -> Bool {
                        switch (lhs, rhs) {
                        case let (.withTuple2(lhs0), .withTuple2(rhs0)):
                            lhs0 == rhs0
                        case let (.withTuple3(lhs0), .withTuple3(rhs0)):
                            lhs0 == rhs0
                        case let (.withTuple5(lhs0), .withTuple5(rhs0)):
                            lhs0 == rhs0
                        case let (.withTuple10(lhs0), .withTuple10(rhs0)):
                            lhs0 == rhs0
                        case let (.withCustomTuple(lhs0), .withCustomTuple(rhs0)):
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

    func testAutoEquatableExcludesVoidAndNever() throws {
        #if canImport(UDFMacrosMacros)
            // Test that Void and Never types are explicitly excluded from equality comparison
            assertMacroExpansion(
                #"""
                @AutoEquatable enum EdgeCaseEnum {
                    case withNormalType(Int)
                    case withVoidType(Void)
                    case withNeverType(Never)
                    case withMixedTypes(Int, Void, String)
                }
                """#,
                expandedSource: #"""
                enum EdgeCaseEnum {
                    case withNormalType(Int)
                    case withVoidType(Void)
                    case withNeverType(Never)
                    case withMixedTypes(Int, Void, String)
                }

                extension EdgeCaseEnum: Equatable {
                    static func ==(lhs: EdgeCaseEnum, rhs: EdgeCaseEnum) -> Bool {
                        switch (lhs, rhs) {
                        case let (.withNormalType(lhs0), .withNormalType(rhs0)):
                            lhs0 == rhs0
                        case let (.withVoidType(_), .withVoidType(_)):
                            true
                        case let (.withNeverType(_), .withNeverType(_)):
                            true
                        case let (.withMixedTypes(lhs0, _, lhs2), .withMixedTypes(rhs0, _, rhs2)):
                            lhs0 == rhs0 && lhs2 == rhs2
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

    func testAutoEquatableIgnoresClosures() throws {
        #if canImport(UDFMacrosMacros)
            assertMacroExpansion(
                #"""
                @AutoEquatable enum ClosureEnum {
                    case withSimpleClosure(() -> Void)
                    case withParameterClosure((Int) -> String)
                    case withMultiParamClosure((Int, String) -> Bool)
                    case withEscapingClosure(@escaping () -> Void)
                    case withEscapingParameterClosure(@escaping (String) -> Int)
                    case withAutoclosure(@autoclosure () -> String)
                    case withSendableClosure(@Sendable () -> Void)
                    case withComplexClosure((Int, String) -> (Bool, Double))
                    case withMixedTypes(id: Int, callback: () -> Void, name: String)
                    case withMultipleMixed(Int, (String) -> Bool, Double, @escaping () -> Void)
                }
                """#,
                expandedSource: #"""
                enum ClosureEnum {
                    case withSimpleClosure(() -> Void)
                    case withParameterClosure((Int) -> String)
                    case withMultiParamClosure((Int, String) -> Bool)
                    case withEscapingClosure(@escaping () -> Void)
                    case withEscapingParameterClosure(@escaping (String) -> Int)
                    case withAutoclosure(@autoclosure () -> String)
                    case withSendableClosure(@Sendable () -> Void)
                    case withComplexClosure((Int, String) -> (Bool, Double))
                    case withMixedTypes(id: Int, callback: () -> Void, name: String)
                    case withMultipleMixed(Int, (String) -> Bool, Double, @escaping () -> Void)
                }

                extension ClosureEnum: Equatable {
                    static func ==(lhs: ClosureEnum, rhs: ClosureEnum) -> Bool {
                        switch (lhs, rhs) {
                        case let (.withSimpleClosure(_), .withSimpleClosure(_)):
                            true
                        case let (.withParameterClosure(_), .withParameterClosure(_)):
                            true
                        case let (.withMultiParamClosure(_), .withMultiParamClosure(_)):
                            true
                        case let (.withEscapingClosure(_), .withEscapingClosure(_)):
                            true
                        case let (.withEscapingParameterClosure(_), .withEscapingParameterClosure(_)):
                            true
                        case let (.withAutoclosure(_), .withAutoclosure(_)):
                            true
                        case let (.withSendableClosure(_), .withSendableClosure(_)):
                            true
                        case let (.withComplexClosure(_), .withComplexClosure(_)):
                            true
                        case let (.withMixedTypes(lhs0, _, lhs2), .withMixedTypes(rhs0, _, rhs2)):
                            lhs0 == rhs0 && lhs2 == rhs2
                        case let (.withMultipleMixed(lhs0, _, lhs2, _), .withMultipleMixed(rhs0, _, rhs2, _)):
                            lhs0 == rhs0 && lhs2 == rhs2
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

    func testAutoEquatableIgnoresClosuresInStructs() throws {
        #if canImport(UDFMacrosMacros)
            assertMacroExpansion(
                #"""
                @AutoEquatable struct ClosureStruct {
                    let id: Int
                    let name: String
                    let onTap: () -> Void
                    let onComplete: @escaping (Bool) -> Void
                    let transform: (String) -> Int
                    let validator: @Sendable (String) -> Bool
                }
                """#,
                expandedSource: #"""
                struct ClosureStruct {
                    let id: Int
                    let name: String
                    let onTap: () -> Void
                    let onComplete: @escaping (Bool) -> Void
                    let transform: (String) -> Int
                    let validator: @Sendable (String) -> Bool
                }

                extension ClosureStruct: Equatable {
                    static func ==(lhs: ClosureStruct, rhs: ClosureStruct) -> Bool {
                        lhs.id == rhs.id && lhs.name == rhs.name
                    }
                }
                """#,
                macros: testMacros
            )
        #else
            throw XCTSkip("macros are only supported when running tests for the host platform")
        #endif
    }

    func testAutoEquatableIgnoresClosuresInClasses() throws {
        #if canImport(UDFMacrosMacros)
            assertMacroExpansion(
                #"""
                @AutoEquatable class ClosureClass {
                    let id: Int
                    let completion: @escaping () -> Void
                    let handler: (String) -> Bool
                    let processor: @Sendable (Data) -> String
                    var counter: Int
                }
                """#,
                expandedSource: #"""
                class ClosureClass {
                    let id: Int
                    let completion: @escaping () -> Void
                    let handler: (String) -> Bool
                    let processor: @Sendable (Data) -> String
                    var counter: Int
                }

                extension ClosureClass: Equatable {
                    static func ==(lhs: ClosureClass, rhs: ClosureClass) -> Bool {
                        lhs.id == rhs.id && lhs.counter == rhs.counter
                    }
                }
                """#,
                macros: testMacros
            )
        #else
            throw XCTSkip("macros are only supported when running tests for the host platform")
        #endif
    }

    func testAutoEquatableForEnumWithAllClosureEdgeCases() throws {
        #if canImport(UDFMacrosMacros)
            assertMacroExpansion(
                #"""
                @AutoEquatable enum ClosureEdgeCasesEnum {
                    case withOptionalClosure(((String) -> Int)?)
                    case withImplicitlyUnwrappedClosure((() -> Void)!)
                    case withNestedClosure(((Int) -> ((String) -> Bool))?)
                    case withThrowingClosure((String) throws -> Int)
                    case withAsyncClosure((String) async -> Int)
                    case withAsyncThrowingClosure((String) async throws -> Int)
                    case withMultipleClosures(
                        callback1: ((Int) -> Void)?,
                        value: String,
                        callback2: (() -> String)?,
                        count: Int,
                        callback3: @escaping (Bool) -> Void
                    )
                }
                """#,
                expandedSource: #"""
                enum ClosureEdgeCasesEnum {
                    case withOptionalClosure(((String) -> Int)?)
                    case withImplicitlyUnwrappedClosure((() -> Void)!)
                    case withNestedClosure(((Int) -> ((String) -> Bool))?)
                    case withThrowingClosure((String) throws -> Int)
                    case withAsyncClosure((String) async -> Int)
                    case withAsyncThrowingClosure((String) async throws -> Int)
                    case withMultipleClosures(
                        callback1: ((Int) -> Void)?,
                        value: String,
                        callback2: (() -> String)?,
                        count: Int,
                        callback3: @escaping (Bool) -> Void
                    )
                }

                extension ClosureEdgeCasesEnum: Equatable {
                    static func ==(lhs: ClosureEdgeCasesEnum, rhs: ClosureEdgeCasesEnum) -> Bool {
                        switch (lhs, rhs) {
                        case let (.withOptionalClosure(_), .withOptionalClosure(_)):
                            true
                        case let (.withImplicitlyUnwrappedClosure(_), .withImplicitlyUnwrappedClosure(_)):
                            true
                        case let (.withNestedClosure(_), .withNestedClosure(_)):
                            true
                        case let (.withThrowingClosure(_), .withThrowingClosure(_)):
                            true
                        case let (.withAsyncClosure(_), .withAsyncClosure(_)):
                            true
                        case let (.withAsyncThrowingClosure(_), .withAsyncThrowingClosure(_)):
                            true
                        case let (.withMultipleClosures(_, lhs1, _, lhs3, _), .withMultipleClosures(_, rhs1, _, rhs3, _)):
                            lhs1 == rhs1 && lhs3 == rhs3
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

    func testAutoEquatableForEnumWithCommandWithTypeAlias() throws {
        #if canImport(UDFMacrosMacros)
            assertMacroExpansion(
                #"""
                public typealias CommandWith<T> = (T) -> Void

                @AutoEquatable enum RouteEnum {
                    case detailsView(
                        postID: Post.ID,
                        isInitiallyInteractive: Bool,
                        triggerAutoScrollAction: CommandWith<AutoScrollTrigger>
                    )
                    case listView(
                        categoryID: Category.ID,
                        onSelectionChanged: CommandWith<Item.ID>,
                        refreshAction: () -> Void
                    )
                    case simpleView(name: String)
                }
                """#,
                expandedSource: #"""
                public typealias CommandWith<T> = (T) -> Void

                enum RouteEnum {
                    case detailsView(
                        postID: Post.ID,
                        isInitiallyInteractive: Bool,
                        triggerAutoScrollAction: CommandWith<AutoScrollTrigger>
                    )
                    case listView(
                        categoryID: Category.ID,
                        onSelectionChanged: CommandWith<Item.ID>,
                        refreshAction: () -> Void
                    )
                    case simpleView(name: String)
                }

                extension RouteEnum: Equatable {
                    static func ==(lhs: RouteEnum, rhs: RouteEnum) -> Bool {
                        switch (lhs, rhs) {
                        case let (.detailsView(lhs0, lhs1, _), .detailsView(rhs0, rhs1, _)):
                            lhs0 == rhs0 && lhs1 == rhs1
                        case let (.listView(lhs0, _, _), .listView(rhs0, _, _)):
                            lhs0 == rhs0
                        case let (.simpleView(lhs0), .simpleView(rhs0)):
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

    // MARK: - AutoHashable Tests

    func testAutoHashableForStruct() throws {
        #if canImport(UDFMacrosMacros)
            assertMacroExpansion(
                #"""
                @AutoHashable struct TestStruct {
                    let id: Int
                    let name: String
                    let value: Double
                    let active: Bool
                }
                """#,
                expandedSource: #"""
                struct TestStruct {
                    let id: Int
                    let name: String
                    let value: Double
                    let active: Bool
                }

                extension TestStruct: Hashable {
                    static func ==(lhs: TestStruct, rhs: TestStruct) -> Bool {
                        lhs.id == rhs.id && lhs.name == rhs.name && lhs.value == rhs.value && lhs.active == rhs.active
                    }
                    func hash(into hasher: inout Hasher) {
                        hasher.combine(id)
                        hasher.combine(name)
                        hasher.combine(value)
                        hasher.combine(active)
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
                    let id: Int
                    let name: String
                    var counter: Int
                }
                """#,
                expandedSource: #"""
                class TestClass {
                    let id: Int
                    let name: String
                    var counter: Int
                }

                extension TestClass: Hashable {
                    static func ==(lhs: TestClass, rhs: TestClass) -> Bool {
                        lhs.id == rhs.id && lhs.name == rhs.name && lhs.counter == rhs.counter
                    }
                    func hash(into hasher: inout Hasher) {
                        hasher.combine(id)
                        hasher.combine(name)
                        hasher.combine(counter)
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
                    case simple
                    case withInt(Int)
                    case withMultiple(Int, String)
                    case withMixed(id: Int, name: String, active: Bool)
                }
                """#,
                expandedSource: #"""
                enum TestEnum {
                    case simple
                    case withInt(Int)
                    case withMultiple(Int, String)
                    case withMixed(id: Int, name: String, active: Bool)
                }

                extension TestEnum: Hashable {
                    static func ==(lhs: TestEnum, rhs: TestEnum) -> Bool {
                        switch (lhs, rhs) {
                        case (.simple, .simple):
                            true
                        case let (.withInt(lhs0), .withInt(rhs0)):
                            lhs0 == rhs0
                        case let (.withMultiple(lhs0, lhs1), .withMultiple(rhs0, rhs1)):
                            lhs0 == rhs0 && lhs1 == rhs1
                        case let (.withMixed(lhs0, lhs1, lhs2), .withMixed(rhs0, rhs1, rhs2)):
                            lhs0 == rhs0 && lhs1 == rhs1 && lhs2 == rhs2
                        default:
                            false
                        }
                    }
                    func hash(into hasher: inout Hasher) {
                        switch self {
                        case .simple:
                            hasher.combine("simple")
                        case let .withInt(value0):
                            hasher.combine("withInt")
                            hasher.combine(value0)
                        case let .withMultiple(value0, value1):
                            hasher.combine("withMultiple")
                            hasher.combine(value0)
                            hasher.combine(value1)
                        case let .withMixed(value0, value1, value2):
                            hasher.combine("withMixed")
                            hasher.combine(value0)
                            hasher.combine(value1)
                            hasher.combine(value2)
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

    func testAutoHashableExcludesClosures() throws {
        #if canImport(UDFMacrosMacros)
            assertMacroExpansion(
                #"""
                @AutoHashable struct ClosureStruct {
                    let id: Int
                    let callback: () -> Void
                    let name: String
                    let handler: @escaping (Int) -> String
                }
                """#,
                expandedSource: #"""
                struct ClosureStruct {
                    let id: Int
                    let callback: () -> Void
                    let name: String
                    let handler: @escaping (Int) -> String
                }

                extension ClosureStruct: Hashable {
                    static func ==(lhs: ClosureStruct, rhs: ClosureStruct) -> Bool {
                        lhs.id == rhs.id && lhs.name == rhs.name
                    }
                    func hash(into hasher: inout Hasher) {
                        hasher.combine(id)
                        hasher.combine(name)
                    }
                }
                """#,
                macros: testMacros
            )
        #else
            throw XCTSkip("macros are only supported when running tests for the host platform")
        #endif
    }

    func testAutoHashableExcludesVoidAndNever() throws {
        #if canImport(UDFMacrosMacros)
            assertMacroExpansion(
                #"""
                @AutoHashable struct EdgeCaseStruct {
                    let id: Int
                    let voidValue: Void
                    let neverValue: Never
                    let name: String
                }
                """#,
                expandedSource: #"""
                struct EdgeCaseStruct {
                    let id: Int
                    let voidValue: Void
                    let neverValue: Never
                    let name: String
                }

                extension EdgeCaseStruct: Hashable {
                    static func ==(lhs: EdgeCaseStruct, rhs: EdgeCaseStruct) -> Bool {
                        lhs.id == rhs.id && lhs.name == rhs.name
                    }
                    func hash(into hasher: inout Hasher) {
                        hasher.combine(id)
                        hasher.combine(name)
                    }
                }
                """#,
                macros: testMacros
            )
        #else
            throw XCTSkip("macros are only supported when running tests for the host platform")
        #endif
    }

    func testAutoHashableWithCollectionsAndOptionals() throws {
        #if canImport(UDFMacrosMacros)
            assertMacroExpansion(
                #"""
                @AutoHashable struct CollectionStruct {
                    let ids: [Int]
                    let names: [String]
                    let optionalId: Int?
                    let optionalName: String?
                    let stringSet: Set<String>
                    let mapping: Dictionary<String, Int>
                }
                """#,
                expandedSource: #"""
                struct CollectionStruct {
                    let ids: [Int]
                    let names: [String]
                    let optionalId: Int?
                    let optionalName: String?
                    let stringSet: Set<String>
                    let mapping: Dictionary<String, Int>
                }

                extension CollectionStruct: Hashable {
                    static func ==(lhs: CollectionStruct, rhs: CollectionStruct) -> Bool {
                        lhs.ids == rhs.ids && lhs.names == rhs.names && lhs.optionalId == rhs.optionalId && lhs.optionalName == rhs.optionalName && lhs.stringSet == rhs.stringSet && lhs.mapping == rhs.mapping
                    }
                    func hash(into hasher: inout Hasher) {
                        hasher.combine(ids)
                        hasher.combine(names)
                        hasher.combine(optionalId)
                        hasher.combine(optionalName)
                        hasher.combine(stringSet)
                        hasher.combine(mapping)
                    }
                }
                """#,
                macros: testMacros
            )
        #else
            throw XCTSkip("macros are only supported when running tests for the host platform")
        #endif
    }

    func testAutoHashableEnumWithClosures() throws {
        #if canImport(UDFMacrosMacros)
            assertMacroExpansion(
                #"""
                @AutoHashable enum ClosureEnum {
                    case withClosure(() -> Void)
                    case withValues(Int, String)
                    case withMixed(id: Int, callback: @escaping () -> Void, name: String)
                }
                """#,
                expandedSource: #"""
                enum ClosureEnum {
                    case withClosure(() -> Void)
                    case withValues(Int, String)
                    case withMixed(id: Int, callback: @escaping () -> Void, name: String)
                }

                extension ClosureEnum: Hashable {
                    static func ==(lhs: ClosureEnum, rhs: ClosureEnum) -> Bool {
                        switch (lhs, rhs) {
                        case let (.withClosure(_), .withClosure(_)):
                            true
                        case let (.withValues(lhs0, lhs1), .withValues(rhs0, rhs1)):
                            lhs0 == rhs0 && lhs1 == rhs1
                        case let (.withMixed(lhs0, _, lhs2), .withMixed(rhs0, _, rhs2)):
                            lhs0 == rhs0 && lhs2 == rhs2
                        default:
                            false
                        }
                    }
                    func hash(into hasher: inout Hasher) {
                        switch self {
                        case .withClosure:
                            hasher.combine("withClosure")
                        case let .withValues(value0, value1):
                            hasher.combine("withValues")
                            hasher.combine(value0)
                            hasher.combine(value1)
                        case let .withMixed(value0, _, value2):
                            hasher.combine("withMixed")
                            hasher.combine(value0)
                            hasher.combine(value2)
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

    func testAutoHashableWorksWithAnyHashableType() throws {
        #if canImport(UDFMacrosMacros)
            assertMacroExpansion(
                #"""
                @AutoHashable struct UnknownTypesStruct {
                    let customType: CustomHashableType
                    let anotherType: SomeOtherHashableType
                    let nestedArray: [[[CustomHashableType]]]
                    let tuple: (CustomHashableType, AnotherHashableType)
                    let optionalCustom: CustomHashableType?
                }
                """#,
                expandedSource: #"""
                struct UnknownTypesStruct {
                    let customType: CustomHashableType
                    let anotherType: SomeOtherHashableType
                    let nestedArray: [[[CustomHashableType]]]
                    let tuple: (CustomHashableType, AnotherHashableType)
                    let optionalCustom: CustomHashableType?
                }

                extension UnknownTypesStruct: Hashable {
                    static func ==(lhs: UnknownTypesStruct, rhs: UnknownTypesStruct) -> Bool {
                        lhs.customType == rhs.customType && lhs.anotherType == rhs.anotherType && lhs.nestedArray == rhs.nestedArray && lhs.tuple == rhs.tuple && lhs.optionalCustom == rhs.optionalCustom
                    }
                    func hash(into hasher: inout Hasher) {
                        hasher.combine(customType)
                        hasher.combine(anotherType)
                        hasher.combine(nestedArray)
                        hasher.combine(tuple)
                        hasher.combine(optionalCustom)
                    }
                }
                """#,
                macros: testMacros
            )
        #else
            throw XCTSkip("macros are only supported when running tests for the host platform")
        #endif
    }

    func testAutoHashableForEnumWithAllClosureEdgeCases() throws {
        #if canImport(UDFMacrosMacros)
            assertMacroExpansion(
                #"""
                @AutoHashable enum ClosureEdgeCasesEnum {
                    case withOptionalClosure(((String) -> Int)?)
                    case withImplicitlyUnwrappedClosure((() -> Void)!)
                    case withNestedClosure(((Int) -> ((String) -> Bool))?)
                    case withThrowingClosure((String) throws -> Int)
                    case withAsyncClosure((String) async -> Int)
                    case withAsyncThrowingClosure((String) async throws -> Int)
                    case withMultipleClosures(
                        callback1: ((Int) -> Void)?,
                        value: String,
                        callback2: (() -> String)?,
                        count: Int,
                        callback3: @escaping (Bool) -> Void
                    )
                }
                """#,
                expandedSource: #"""
                enum ClosureEdgeCasesEnum {
                    case withOptionalClosure(((String) -> Int)?)
                    case withImplicitlyUnwrappedClosure((() -> Void)!)
                    case withNestedClosure(((Int) -> ((String) -> Bool))?)
                    case withThrowingClosure((String) throws -> Int)
                    case withAsyncClosure((String) async -> Int)
                    case withAsyncThrowingClosure((String) async throws -> Int)
                    case withMultipleClosures(
                        callback1: ((Int) -> Void)?,
                        value: String,
                        callback2: (() -> String)?,
                        count: Int,
                        callback3: @escaping (Bool) -> Void
                    )
                }

                extension ClosureEdgeCasesEnum: Hashable {
                    static func ==(lhs: ClosureEdgeCasesEnum, rhs: ClosureEdgeCasesEnum) -> Bool {
                        switch (lhs, rhs) {
                        case let (.withOptionalClosure(_), .withOptionalClosure(_)):
                            true
                        case let (.withImplicitlyUnwrappedClosure(_), .withImplicitlyUnwrappedClosure(_)):
                            true
                        case let (.withNestedClosure(_), .withNestedClosure(_)):
                            true
                        case let (.withThrowingClosure(_), .withThrowingClosure(_)):
                            true
                        case let (.withAsyncClosure(_), .withAsyncClosure(_)):
                            true
                        case let (.withAsyncThrowingClosure(_), .withAsyncThrowingClosure(_)):
                            true
                        case let (.withMultipleClosures(_, lhs1, _, lhs3, _), .withMultipleClosures(_, rhs1, _, rhs3, _)):
                            lhs1 == rhs1 && lhs3 == rhs3
                        default:
                            false
                        }
                    }
                    func hash(into hasher: inout Hasher) {
                        switch self {
                        case .withOptionalClosure:
                            hasher.combine("withOptionalClosure")
                        case .withImplicitlyUnwrappedClosure:
                            hasher.combine("withImplicitlyUnwrappedClosure")
                        case .withNestedClosure:
                            hasher.combine("withNestedClosure")
                        case .withThrowingClosure:
                            hasher.combine("withThrowingClosure")
                        case .withAsyncClosure:
                            hasher.combine("withAsyncClosure")
                        case .withAsyncThrowingClosure:
                            hasher.combine("withAsyncThrowingClosure")
                        case let .withMultipleClosures(_, value1, _, value3, _):
                            hasher.combine("withMultipleClosures")
                            hasher.combine(value1)
                            hasher.combine(value3)
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

    func testAutoHashableForEnumWithCommandWithTypeAlias() throws {
        #if canImport(UDFMacrosMacros)
            assertMacroExpansion(
                #"""
                public typealias CommandWith<T> = (T) -> Void

                @AutoHashable enum RouteEnum {
                    case detailsView(
                        postID: Post.ID,
                        isInitiallyInteractive: Bool,
                        triggerAutoScrollAction: CommandWith<AutoScrollTrigger>
                    )
                    case listView(
                        categoryID: Category.ID,
                        onSelectionChanged: CommandWith<Item.ID>,
                        refreshAction: () -> Void
                    )
                    case simpleView(name: String)
                }
                """#,
                expandedSource: #"""
                public typealias CommandWith<T> = (T) -> Void

                enum RouteEnum {
                    case detailsView(
                        postID: Post.ID,
                        isInitiallyInteractive: Bool,
                        triggerAutoScrollAction: CommandWith<AutoScrollTrigger>
                    )
                    case listView(
                        categoryID: Category.ID,
                        onSelectionChanged: CommandWith<Item.ID>,
                        refreshAction: () -> Void
                    )
                    case simpleView(name: String)
                }

                extension RouteEnum: Hashable {
                    static func ==(lhs: RouteEnum, rhs: RouteEnum) -> Bool {
                        switch (lhs, rhs) {
                        case let (.detailsView(lhs0, lhs1, _), .detailsView(rhs0, rhs1, _)):
                            lhs0 == rhs0 && lhs1 == rhs1
                        case let (.listView(lhs0, _, _), .listView(rhs0, _, _)):
                            lhs0 == rhs0
                        case let (.simpleView(lhs0), .simpleView(rhs0)):
                            lhs0 == rhs0
                        default:
                            false
                        }
                    }
                    func hash(into hasher: inout Hasher) {
                        switch self {
                        case let .detailsView(value0, value1, _):
                            hasher.combine("detailsView")
                            hasher.combine(value0)
                            hasher.combine(value1)
                        case let .listView(value0, _, _):
                            hasher.combine("listView")
                            hasher.combine(value0)
                        case let .simpleView(value0):
                            hasher.combine("simpleView")
                            hasher.combine(value0)
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

    // MARK: - Storage Tests

    func testStorageBasicExpansion() throws {
        #if canImport(UDFMacrosMacros)
            assertMacroExpansion(
                """
                @Storage(Movie.self)
                struct AllMovies: Reducible {
                }
                """,
                expandedSource: """
                struct AllMovies: Reducible {

                    var byId: [Movie.ID: Movie] = [:]

                    mutating func reduce(_ action: some Action) {
                        switch action {
                        case let action as Actions.DidLoadItems<Movie>:
                            byId.insert(items: action.items)

                        case let action as Actions.DidLoadItem<Movie>:
                            byId.insert(item: action.item)

                        case let action as Actions.DidUpdateItem<Movie>:
                            byId[action.item.id] = action.item

                        case let action as Actions.DeleteItem<Movie>:
                            byId.removeValue(forKey: action.item.id)

                        default:
                            break
                        }
                    }

                    func movieBy(id: Movie.ID) -> Movie {
                        byId[id] ?? .empty
                    }
                }
                """,
                macros: testMacros
            )
        #else
            throw XCTSkip("macros are only supported when running tests for the host platform")
        #endif
    }

    /// Acronym-led type names ("FAQItem") should lower only the leading
    /// uppercase run, not just the first letter.
    func testStorageAccessorNamingForAcronymLeadingType() throws {
        #if canImport(UDFMacrosMacros)
            assertMacroExpansion(
                """
                @Storage(FAQItem.self)
                struct AllFAQItems: Reducible {
                }
                """,
                expandedSource: """
                struct AllFAQItems: Reducible {

                    var byId: [FAQItem.ID: FAQItem] = [:]

                    mutating func reduce(_ action: some Action) {
                        switch action {
                        case let action as Actions.DidLoadItems<FAQItem>:
                            byId.insert(items: action.items)

                        case let action as Actions.DidLoadItem<FAQItem>:
                            byId.insert(item: action.item)

                        case let action as Actions.DidUpdateItem<FAQItem>:
                            byId[action.item.id] = action.item

                        case let action as Actions.DeleteItem<FAQItem>:
                            byId.removeValue(forKey: action.item.id)

                        default:
                            break
                        }
                    }

                    func faqItemBy(id: FAQItem.ID) -> FAQItem {
                        byId[id] ?? .empty
                    }
                }
                """,
                macros: testMacros
            )
        #else
            throw XCTSkip("macros are only supported when running tests for the host platform")
        #endif
    }

    /// The escape hatch: a hand-written `reduce` (e.g. for a bespoke action
    /// like `DidToggleFavorite`) is left untouched — `byId` and the accessor
    /// are still generated.
    func testStorageSkipsExistingReduce() throws {
        #if canImport(UDFMacrosMacros)
            assertMacroExpansion(
                """
                @Storage(Movie.self)
                struct AllMovies: Reducible {
                    mutating func reduce(_ action: some Action) {
                        switch action {
                        case let action as Actions.DidToggleFavorite<Movie>:
                            byId[action.id]?.isFavorite.toggle()
                        default:
                            break
                        }
                    }
                }
                """,
                expandedSource: """
                struct AllMovies: Reducible {
                    mutating func reduce(_ action: some Action) {
                        switch action {
                        case let action as Actions.DidToggleFavorite<Movie>:
                            byId[action.id]?.isFavorite.toggle()
                        default:
                            break
                        }
                    }

                    var byId: [Movie.ID: Movie] = [:]

                    func movieBy(id: Movie.ID) -> Movie {
                        byId[id] ?? .empty
                    }
                }
                """,
                macros: testMacros
            )
        #else
            throw XCTSkip("macros are only supported when running tests for the host platform")
        #endif
    }

    /// A hand-written accessor with the same name is left untouched too.
    func testStorageSkipsExistingAccessor() throws {
        #if canImport(UDFMacrosMacros)
            assertMacroExpansion(
                """
                @Storage(Movie.self)
                struct AllMovies: Reducible {
                    func movieBy(id: Movie.ID) -> Movie {
                        byId[id] ?? .empty
                    }
                }
                """,
                expandedSource: """
                struct AllMovies: Reducible {
                    func movieBy(id: Movie.ID) -> Movie {
                        byId[id] ?? .empty
                    }

                    var byId: [Movie.ID: Movie] = [:]

                    mutating func reduce(_ action: some Action) {
                        switch action {
                        case let action as Actions.DidLoadItems<Movie>:
                            byId.insert(items: action.items)

                        case let action as Actions.DidLoadItem<Movie>:
                            byId.insert(item: action.item)

                        case let action as Actions.DidUpdateItem<Movie>:
                            byId[action.item.id] = action.item

                        case let action as Actions.DeleteItem<Movie>:
                            byId.removeValue(forKey: action.item.id)

                        default:
                            break
                        }
                    }
                }
                """,
                macros: testMacros
            )
        #else
            throw XCTSkip("macros are only supported when running tests for the host platform")
        #endif
    }

    /// Regression test: an existing overload with a DIFFERENT label
    /// (`restaurantBy(review:)`) must not be mistaken for the macro's own
    /// `restaurantBy(id:)` — matching on bare function name previously
    /// caused the macro to silently skip generating `restaurantBy(id:)`
    /// whenever any other `restaurantBy(...)` overload already existed.
    func testStorageGeneratesAccessorDespiteDifferentlyLabeledOverload() throws {
        #if canImport(UDFMacrosMacros)
            assertMacroExpansion(
                """
                @Storage(Restaurant.self)
                struct AllRestaurants: Reducible {
                    func restaurantBy(review id: Review.ID) -> Restaurant.ID? {
                        byReviewId[id]
                    }
                }
                """,
                expandedSource: """
                struct AllRestaurants: Reducible {
                    func restaurantBy(review id: Review.ID) -> Restaurant.ID? {
                        byReviewId[id]
                    }

                    var byId: [Restaurant.ID: Restaurant] = [:]

                    mutating func reduce(_ action: some Action) {
                        switch action {
                        case let action as Actions.DidLoadItems<Restaurant>:
                            byId.insert(items: action.items)

                        case let action as Actions.DidLoadItem<Restaurant>:
                            byId.insert(item: action.item)

                        case let action as Actions.DidUpdateItem<Restaurant>:
                            byId[action.item.id] = action.item

                        case let action as Actions.DeleteItem<Restaurant>:
                            byId.removeValue(forKey: action.item.id)

                        default:
                            break
                        }
                    }

                    func restaurantBy(id: Restaurant.ID) -> Restaurant {
                        byId[id] ?? .empty
                    }
                }
                """,
                macros: testMacros
            )
        #else
            throw XCTSkip("macros are only supported when running tests for the host platform")
        #endif
    }

    /// If the struct declares `reduceCustom`, the generated `reduce`'s
    /// `default:` delegates to it instead of `break`.
    func testStorageWiresReduceCustomWhenDeclared() throws {
        #if canImport(UDFMacrosMacros)
            assertMacroExpansion(
                """
                @Storage(Dish.self)
                struct AllDishes: Reducible {
                    mutating func reduceCustom(_ action: some Action) {
                        switch action {
                        case let action as Actions.DidDislikeDish:
                            byId[action.dishID]?.isLiked = false
                        default:
                            break
                        }
                    }
                }
                """,
                expandedSource: """
                struct AllDishes: Reducible {
                    mutating func reduceCustom(_ action: some Action) {
                        switch action {
                        case let action as Actions.DidDislikeDish:
                            byId[action.dishID]?.isLiked = false
                        default:
                            break
                        }
                    }

                    var byId: [Dish.ID: Dish] = [:]

                    mutating func reduce(_ action: some Action) {
                        switch action {
                        case let action as Actions.DidLoadItems<Dish>:
                            byId.insert(items: action.items)

                        case let action as Actions.DidLoadItem<Dish>:
                            byId.insert(item: action.item)

                        case let action as Actions.DidUpdateItem<Dish>:
                            byId[action.item.id] = action.item

                        case let action as Actions.DeleteItem<Dish>:
                            byId.removeValue(forKey: action.item.id)

                        default:
                            reduceCustom(action)
                        }
                    }

                    func dishBy(id: Dish.ID) -> Dish {
                        byId[id] ?? .empty
                    }
                }
                """,
                macros: testMacros
            )
        #else
            throw XCTSkip("macros are only supported when running tests for the host platform")
        #endif
    }

    /// Without a declared `reduceCustom`, `default:` stays `break` exactly
    /// as before — no behavior change for storages that don't need a hook.
    func testStorageDefaultCaseStaysBreakWithoutReduceCustom() throws {
        #if canImport(UDFMacrosMacros)
            assertMacroExpansion(
                """
                @Storage(Dish.self)
                struct AllDishes: Reducible {
                }
                """,
                expandedSource: """
                struct AllDishes: Reducible {

                    var byId: [Dish.ID: Dish] = [:]

                    mutating func reduce(_ action: some Action) {
                        switch action {
                        case let action as Actions.DidLoadItems<Dish>:
                            byId.insert(items: action.items)

                        case let action as Actions.DidLoadItem<Dish>:
                            byId.insert(item: action.item)

                        case let action as Actions.DidUpdateItem<Dish>:
                            byId[action.item.id] = action.item

                        case let action as Actions.DeleteItem<Dish>:
                            byId.removeValue(forKey: action.item.id)

                        default:
                            break
                        }
                    }

                    func dishBy(id: Dish.ID) -> Dish {
                        byId[id] ?? .empty
                    }
                }
                """,
                macros: testMacros
            )
        #else
            throw XCTSkip("macros are only supported when running tests for the host platform")
        #endif
    }

    func testStorageRequiresStruct() throws {
        #if canImport(UDFMacrosMacros)
            assertMacroExpansion(
                """
                @Storage(Movie.self)
                class AllMovies: Reducible {
                }
                """,
                expandedSource: """
                class AllMovies: Reducible {
                }
                """,
                diagnostics: [
                    DiagnosticSpec(message: "@Storage can only be applied to a 'struct' declaration", line: 1, column: 1),
                ],
                macros: testMacros
            )
        #else
            throw XCTSkip("macros are only supported when running tests for the host platform")
        #endif
    }

    func testStorageInvalidArgument() throws {
        #if canImport(UDFMacrosMacros)
            assertMacroExpansion(
                """
                @Storage("Movie")
                struct AllMovies: Reducible {
                }
                """,
                expandedSource: """
                struct AllMovies: Reducible {
                }
                """,
                diagnostics: [
                    DiagnosticSpec(message: "@Storage requires a single argument in the form 'TypeName.self'", line: 1, column: 1),
                ],
                macros: testMacros
            )
        #else
            throw XCTSkip("macros are only supported when running tests for the host platform")
        #endif
    }

    // MARK: - StorageRelationships Tests

    /// Single hasOne relationship, default name/label. Only DidLoadNestedItem is
    /// generated — bulk "by parents" loading is app-level and out of scope.
    func testStorageRelationshipsSingleHasOneDefaultNaming() throws {
        #if canImport(UDFMacrosMacros)
            assertMacroExpansion(
                """
                @Storage(Restaurant.self)
                @StorageRelationships(
                    .hasOne(Review.self)
                )
                struct AllRestaurants: Reducible {
                }
                """,
                expandedSource: """
                struct AllRestaurants: Reducible {

                    var byId: [Restaurant.ID: Restaurant] = [:]

                    mutating func reduce(_ action: some Action) {
                        switch action {
                        case let action as Actions.DidLoadItems<Restaurant>:
                            byId.insert(items: action.items)

                        case let action as Actions.DidLoadItem<Restaurant>:
                            byId.insert(item: action.item)

                        case let action as Actions.DidUpdateItem<Restaurant>:
                            byId[action.item.id] = action.item

                        case let action as Actions.DeleteItem<Restaurant>:
                            byId.removeValue(forKey: action.item.id)

                        default:
                            reduceRelationships(action)
                        }
                    }

                    func restaurantBy(id: Restaurant.ID) -> Restaurant {
                        byId[id] ?? .empty
                    }

                    var byReviewId: [Review.ID: Restaurant.ID] = [:]

                    mutating func reduceRelationships(_ action: some Action) {
                        switch action {
                        case let action as Actions.DidLoadNestedItem<Review.ID, Restaurant>:
                            byId.insert(item: action.item)
                            byReviewId[action.parentId] = action.item.id

                        default:
                            break
                        }
                    }

                    func restaurantBy(review id: Review.ID) -> Restaurant.ID? {
                        byReviewId[id]
                    }
                }
                """,
                macros: testMacros
            )
        #else
            throw XCTSkip("macros are only supported when running tests for the host platform")
        #endif
    }

    /// Three relationships in one call. Note: to match the *exact* existing
    /// AllRestaurants naming (`byFortuneResultId`, not the default
    /// `byFortuneWheelResultId`), `name:` is passed alongside `label:` — they're
    /// independent overrides, and `label:` alone only changes the accessor's
    /// argument label, not the storage property name.
    func testStorageRelationshipsMultipleWithLabelOverrides() throws {
        #if canImport(UDFMacrosMacros)
            assertMacroExpansion(
                """
                @Storage(Restaurant.self)
                @StorageRelationships(
                    .hasOne(Review.self),
                    .hasOne(FortuneWheelResult.self, name: "byFortuneResultId", label: "fortuneResult"),
                    .hasOne(Dish.self, label: "dishID")
                )
                struct AllRestaurants: Reducible {
                }
                """,
                expandedSource: """
                struct AllRestaurants: Reducible {

                    var byId: [Restaurant.ID: Restaurant] = [:]

                    mutating func reduce(_ action: some Action) {
                        switch action {
                        case let action as Actions.DidLoadItems<Restaurant>:
                            byId.insert(items: action.items)

                        case let action as Actions.DidLoadItem<Restaurant>:
                            byId.insert(item: action.item)

                        case let action as Actions.DidUpdateItem<Restaurant>:
                            byId[action.item.id] = action.item

                        case let action as Actions.DeleteItem<Restaurant>:
                            byId.removeValue(forKey: action.item.id)

                        default:
                            reduceRelationships(action)
                        }
                    }

                    func restaurantBy(id: Restaurant.ID) -> Restaurant {
                        byId[id] ?? .empty
                    }

                    var byReviewId: [Review.ID: Restaurant.ID] = [:]

                    var byFortuneResultId: [FortuneWheelResult.ID: Restaurant.ID] = [:]

                    var byDishId: [Dish.ID: Restaurant.ID] = [:]

                    mutating func reduceRelationships(_ action: some Action) {
                        switch action {
                        case let action as Actions.DidLoadNestedItem<Review.ID, Restaurant>:
                            byId.insert(item: action.item)
                            byReviewId[action.parentId] = action.item.id

                        case let action as Actions.DidLoadNestedItem<FortuneWheelResult.ID, Restaurant>:
                            byId.insert(item: action.item)
                            byFortuneResultId[action.parentId] = action.item.id

                        case let action as Actions.DidLoadNestedItem<Dish.ID, Restaurant>:
                            byId.insert(item: action.item)
                            byDishId[action.parentId] = action.item.id

                        default:
                            break
                        }
                    }

                    func restaurantBy(review id: Review.ID) -> Restaurant.ID? {
                        byReviewId[id]
                    }

                    func restaurantBy(fortuneResult id: FortuneWheelResult.ID) -> Restaurant.ID? {
                        byFortuneResultId[id]
                    }

                    func restaurantBy(dishID id: Dish.ID) -> Restaurant.ID? {
                        byDishId[id]
                    }
                }
                """,
                macros: testMacros
            )
        #else
            throw XCTSkip("macros are only supported when running tests for the host platform")
        #endif
    }

    /// @StorageRelationships without @Storage on the same declaration is a
    /// compile-time error, not a silently-inert reduceRelationships(_:).
    func testStorageRelationshipsRequiresStorage() throws {
        #if canImport(UDFMacrosMacros)
            assertMacroExpansion(
                """
                @StorageRelationships(.hasOne(Review.self))
                struct AllRestaurants: Reducible {
                }
                """,
                expandedSource: """
                struct AllRestaurants: Reducible {
                }
                """,
                diagnostics: [
                    DiagnosticSpec(
                        message: "@StorageRelationships requires @Storage(_:) on the same declaration — without it, the generated reduceRelationships(_:) is never called.",
                        line: 1,
                        column: 1
                    ),
                ],
                macros: testMacros
            )
        #else
            throw XCTSkip("macros are only supported when running tests for the host platform")
        #endif
    }

    /// Two relationships to the same parent type without an explicit `name:`
    /// collide on the default `by<Parent>Id` name — must be a diagnostic, not a
    /// silent duplicate declaration.
    func testStorageRelationshipsDuplicateNameDiagnostic() throws {
        #if canImport(UDFMacrosMacros)
            assertMacroExpansion(
                """
                @Storage(Movie.self)
                @StorageRelationships(
                    .hasOne(Person.self),
                    .hasOne(Person.self)
                )
                struct AllMovies: Reducible {
                }
                """,
                expandedSource: """
                struct AllMovies: Reducible {

                    var byId: [Movie.ID: Movie] = [:]

                    mutating func reduce(_ action: some Action) {
                        switch action {
                        case let action as Actions.DidLoadItems<Movie>:
                            byId.insert(items: action.items)

                        case let action as Actions.DidLoadItem<Movie>:
                            byId.insert(item: action.item)

                        case let action as Actions.DidUpdateItem<Movie>:
                            byId[action.item.id] = action.item

                        case let action as Actions.DeleteItem<Movie>:
                            byId.removeValue(forKey: action.item.id)

                        default:
                            reduceRelationships(action)
                        }
                    }

                    func movieBy(id: Movie.ID) -> Movie {
                        byId[id] ?? .empty
                    }
                }
                """,
                diagnostics: [
                    DiagnosticSpec(message: "Relationship name 'byPersonId' is used more than once. Pass an explicit `name:` to disambiguate two relationships to the same parent type.", line: 4, column: 5),
                ],
                macros: testMacros
            )
        #else
            throw XCTSkip("macros are only supported when running tests for the host platform")
        #endif
    }

    /// Both reduceRelationships(_:) and a user-written reduceCustom(_:) fire from
    /// default: — not exclusive-or.
    func testStorageWiresBothRelationshipsAndReduceCustom() throws {
        #if canImport(UDFMacrosMacros)
            assertMacroExpansion(
                """
                @Storage(Restaurant.self)
                @StorageRelationships(
                    .hasOne(Review.self)
                )
                struct AllRestaurants: Reducible {
                    mutating func reduceCustom(_ action: some Action) {
                        switch action {
                        case let action as Actions.DidDeleteRestaurantFromCollection:
                            byId[action.restaurantID]?.isCollectedByCurrentUser = action.isContainedInOtherCollections
                        default:
                            break
                        }
                    }
                }
                """,
                expandedSource: """
                struct AllRestaurants: Reducible {
                    mutating func reduceCustom(_ action: some Action) {
                        switch action {
                        case let action as Actions.DidDeleteRestaurantFromCollection:
                            byId[action.restaurantID]?.isCollectedByCurrentUser = action.isContainedInOtherCollections
                        default:
                            break
                        }
                    }

                    var byId: [Restaurant.ID: Restaurant] = [:]

                    mutating func reduce(_ action: some Action) {
                        switch action {
                        case let action as Actions.DidLoadItems<Restaurant>:
                            byId.insert(items: action.items)

                        case let action as Actions.DidLoadItem<Restaurant>:
                            byId.insert(item: action.item)

                        case let action as Actions.DidUpdateItem<Restaurant>:
                            byId[action.item.id] = action.item

                        case let action as Actions.DeleteItem<Restaurant>:
                            byId.removeValue(forKey: action.item.id)

                        default:
                            reduceRelationships(action)
                            reduceCustom(action)
                        }
                    }

                    func restaurantBy(id: Restaurant.ID) -> Restaurant {
                        byId[id] ?? .empty
                    }

                    var byReviewId: [Review.ID: Restaurant.ID] = [:]

                    mutating func reduceRelationships(_ action: some Action) {
                        switch action {
                        case let action as Actions.DidLoadNestedItem<Review.ID, Restaurant>:
                            byId.insert(item: action.item)
                            byReviewId[action.parentId] = action.item.id

                        default:
                            break
                        }
                    }

                    func restaurantBy(review id: Review.ID) -> Restaurant.ID? {
                        byReviewId[id]
                    }
                }
                """,
                macros: testMacros
            )
        #else
            throw XCTSkip("macros are only supported when running tests for the host platform")
        #endif
    }

    /// .hasMany is deliberately unimplemented — a clear diagnostic, not guessed code.
    /// Note: @Storage still generates its own members (byId/reduce/accessor)
    /// regardless — its hasRelationships check is name-only (it can't see whether
    /// the sibling macro actually succeeded), so `reduceRelationships(action)` is
    /// still called in `default:` even though @StorageRelationships produced
    /// nothing here. That's fine: the diagnostic below already fails the build,
    /// this just documents that @Storage's own output is unaffected.
    func testStorageRelationshipsHasManyNotYetSupported() throws {
        #if canImport(UDFMacrosMacros)
            assertMacroExpansion(
                """
                @Storage(Dish.self)
                @StorageRelationships(
                    .hasMany(Restaurant.self)
                )
                struct AllDishes: Reducible {
                }
                """,
                expandedSource: """
                struct AllDishes: Reducible {

                    var byId: [Dish.ID: Dish] = [:]

                    mutating func reduce(_ action: some Action) {
                        switch action {
                        case let action as Actions.DidLoadItems<Dish>:
                            byId.insert(items: action.items)

                        case let action as Actions.DidLoadItem<Dish>:
                            byId.insert(item: action.item)

                        case let action as Actions.DidUpdateItem<Dish>:
                            byId[action.item.id] = action.item

                        case let action as Actions.DeleteItem<Dish>:
                            byId.removeValue(forKey: action.item.id)

                        default:
                            reduceRelationships(action)
                        }
                    }

                    func dishBy(id: Dish.ID) -> Dish {
                        byId[id] ?? .empty
                    }
                }
                """,
                diagnostics: [
                    DiagnosticSpec(
                        message: "@StorageRelationships does not generate .hasMany relationships yet — write this one by hand for now (deliberately deferred, not guessed at).",
                        line: 3,
                        column: 5
                    ),
                ],
                macros: testMacros
            )
        #else
            throw XCTSkip("macros are only supported when running tests for the host platform")
        #endif
    }
}
