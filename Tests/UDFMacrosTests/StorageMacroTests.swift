import SwiftSyntax
import SwiftSyntaxBuilder
import SwiftSyntaxMacros
import SwiftSyntaxMacrosTestSupport
import XCTest

final class StorageMacroTests: XCTestCase {
    func testStorageBasicExpansion() throws {
        #if canImport(UDFMacrosMacros)
            assertMacroExpansion(
                """
                @Storage(Movie.self)
                struct AllMovies: Storage {
                }
                """,
                expandedSource: """
                struct AllMovies: Storage {

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

    /// UDF 2.0 formalizes `Storage` as a real protocol. When the attached
    /// struct doesn't already spell out ": Storage" (or anything else) in
    /// its own inheritance clause, @Storage auto-conforms it via a generated
    /// `extension AllX: Storage {}` — no hand-written conformance needed.
    func testStorageAutoConformsWhenMissing() throws {
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

                extension AllMovies: Storage {
                }
                """,
                macros: testMacros
            )
        #else
            throw XCTSkip("macros are only supported when running tests for the host platform")
        #endif
    }

    /// When the struct already declares `: Storage` itself, the macro must
    /// NOT also generate `extension AllX: Storage {}` — Swift treats a
    /// second declaration of the same conformance as a hard "redundant
    /// conformance" error, not a warning.
    func testStorageSkipsConformanceWhenAlreadyDeclared() throws {
        #if canImport(UDFMacrosMacros)
            assertMacroExpansion(
                """
                @Storage(Movie.self)
                struct AllMovies: Storage {
                }
                """,
                expandedSource: """
                struct AllMovies: Storage {

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
                struct AllFAQItems: Storage {
                }
                """,
                expandedSource: """
                struct AllFAQItems: Storage {

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
                struct AllMovies: Storage {
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
                struct AllMovies: Storage {
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
                diagnostics: [
                    DiagnosticSpec(
                        message: "This struct declares 'reduce(_:)' by hand, so @Storage won't generate the standard DidLoadItems/DidLoadItem/DidUpdateItem/DeleteItem handling. Consider moving custom logic into 'reduceCustom(_:)' instead, so the standard cases are generated automatically.",
                        line: 3,
                        column: 5,
                        severity: .warning
                    ),
                ],
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
                struct AllMovies: Storage {
                    func movieBy(id: Movie.ID) -> Movie {
                        byId[id] ?? .empty
                    }
                }
                """,
                expandedSource: """
                struct AllMovies: Storage {
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
                struct AllRestaurants: Storage {
                    func restaurantBy(review id: Review.ID) -> Restaurant.ID? {
                        byReviewId[id]
                    }
                }
                """,
                expandedSource: """
                struct AllRestaurants: Storage {
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
                struct AllDishes: Storage {
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
                struct AllDishes: Storage {
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
                struct AllDishes: Storage {
                }
                """,
                expandedSource: """
                struct AllDishes: Storage {

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
                class AllMovies: Storage {
                }
                """,
                expandedSource: """
                class AllMovies: Storage {
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
                struct AllMovies: Storage {
                }
                """,
                expandedSource: """
                struct AllMovies: Storage {
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

    /// Both _reduceRelationships(_:) and a user-written reduceCustom(_:) fire from
    /// default: — not exclusive-or.
    func testStorageWiresBothRelationshipsAndReduceCustom() throws {
        #if canImport(UDFMacrosMacros)
            assertMacroExpansion(
                """
                @Storage(Restaurant.self)
                @StorageRelationships(
                    .hasOne(Review.self)
                )
                struct AllRestaurants: Storage {
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
                struct AllRestaurants: Storage {
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
                            _reduceRelationships(action)
                            reduceCustom(action)
                        }
                    }

                    func restaurantBy(id: Restaurant.ID) -> Restaurant {
                        byId[id] ?? .empty
                    }

                    var byReviewId: [Review.ID: Restaurant.ID] = [:]

                    mutating func _reduceRelationships(_ action: some Action) {
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
}
