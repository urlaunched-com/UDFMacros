import SwiftSyntax
import SwiftSyntaxBuilder
import SwiftSyntaxMacros
import SwiftSyntaxMacrosTestSupport
import XCTest

final class AutoHashableMacroTests: XCTestCase {
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

    func testAutoHashableForEnumWithCustomClosureTypeAliasViaIgnoringTypeNames() throws {
        #if canImport(UDFMacrosMacros)
            assertMacroExpansion(
                #"""
                typealias CommandWith<T> = (T) -> Void

                @AutoHashable(ignoringTypeNames: ["CommandWith"]) enum Route {
                    case details(id: String, action: CommandWith<Item>)
                    case simple(name: String)
                }
                """#,
                expandedSource: #"""
                typealias CommandWith<T> = (T) -> Void

                enum Route {
                    case details(id: String, action: CommandWith<Item>)
                    case simple(name: String)
                }

                extension Route: Hashable {
                    static func ==(lhs: Route, rhs: Route) -> Bool {
                        switch (lhs, rhs) {
                        case let (.details(lhs0, _), .details(rhs0, _)):
                            lhs0 == rhs0
                        case let (.simple(lhs0), .simple(rhs0)):
                            lhs0 == rhs0
                        default:
                            false
                        }
                    }
                    func hash(into hasher: inout Hasher) {
                        switch self {
                        case let .details(value0, _):
                            hasher.combine("details")
                            hasher.combine(value0)
                        case let .simple(value0):
                            hasher.combine("simple")
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
}
