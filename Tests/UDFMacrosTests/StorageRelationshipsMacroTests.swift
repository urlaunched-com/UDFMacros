import SwiftSyntax
import SwiftSyntaxBuilder
import SwiftSyntaxMacros
import SwiftSyntaxMacrosTestSupport
import XCTest

final class StorageRelationshipsMacroTests: XCTestCase {
    // MARK: - StorageRelationships .hasOne Tests

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
                            _reduceRelationships(action)
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
                            _reduceRelationships(action)
                        }
                    }

                    func restaurantBy(id: Restaurant.ID) -> Restaurant {
                        byId[id] ?? .empty
                    }

                    var byReviewId: [Review.ID: Restaurant.ID] = [:]

                    var byFortuneResultId: [FortuneWheelResult.ID: Restaurant.ID] = [:]

                    var byDishId: [Dish.ID: Restaurant.ID] = [:]

                    mutating func _reduceRelationships(_ action: some Action) {
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
    /// compile-time error, not a silently-inert _reduceRelationships(_:).
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
                        message: "@StorageRelationships requires @Storage(_:) on the same declaration — without it, the generated _reduceRelationships(_:) is never called.",
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
                    .hasMany(Personnel.self, name: "byPersonId")
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
                            _reduceRelationships(action)
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

    // MARK: - StorageRelationships .hasMany Tests

    /// Single hasMany relationship, default naming. Uses the same Dish/Restaurant
    /// pair as the real hand-written AllDishes, so the generated output can be
    /// diffed directly against it: default name is `byRestaurantId` (not `byMovie`
    /// / not pluralized) — the key is still a single Restaurant.ID, only the
    /// *value* is a collection. Three reduce cases are generated (DidLoadNestedItem,
    /// DidLoadNestedItems, DidLoadNestedByParents), all additive via `.append`,
    /// matching the union convention confirmed in the real AllDishes/AllReviews.
    func testStorageRelationshipsSingleHasManyDefaultNaming() throws {
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
                            _reduceRelationships(action)
                        }
                    }

                    func dishBy(id: Dish.ID) -> Dish {
                        byId[id] ?? .empty
                    }

                    var byRestaurantId: [Restaurant.ID: OrderedSet<Dish.ID>] = [:]

                    mutating func _reduceRelationships(_ action: some Action) {
                        switch action {
                        case let action as Actions.DidLoadNestedItem<Restaurant.ID, Dish>:
                            byId.insert(item: action.item)
                            byRestaurantId.append(action.item.id, by: action.parentId)

                        case let action as Actions.DidLoadNestedItems<Restaurant.ID, Dish>:
                            byId.insert(items: action.items)
                            byRestaurantId.append(action.items.ids, by: action.parentId)

                        case let action as Actions.DidLoadNestedByParents<Restaurant.ID, Dish>:
                            for (parentId, children) in action.dictionary {
                                byId.insert(items: children)
                                byRestaurantId.append(children.ids, by: parentId)
                            }

                        case let action as Actions.DeleteNestedItem<Restaurant.ID, Dish>:
                            byId.removeValue(forKey: action.item.id)
                            byRestaurantId[action.parentId]?.remove(action.item.id)

                        default:
                            break
                        }
                    }

                    func dishesBy(restaurant id: Restaurant.ID) -> [Dish.ID] {
                        Array(byRestaurantId[id] ?? [])
                    }
                }
                """,
                macros: testMacros
            )
        #else
            throw XCTSkip("macros are only supported when running tests for the host platform")
        #endif
    }

    /// hasOne and hasMany in the same @StorageRelationships call, to different
    /// parent types — no collision, both generate correctly, ordered hasOne-first
    /// throughout (properties, reduce cases, accessors).
    func testStorageRelationshipsMixedHasOneAndHasMany() throws {
        #if canImport(UDFMacrosMacros)
            assertMacroExpansion(
                """
                @Storage(Restaurant.self)
                @StorageRelationships(
                    .hasOne(Review.self),
                    .hasMany(Category.self)
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
                            _reduceRelationships(action)
                        }
                    }

                    func restaurantBy(id: Restaurant.ID) -> Restaurant {
                        byId[id] ?? .empty
                    }

                    var byReviewId: [Review.ID: Restaurant.ID] = [:]

                    var byCategoryId: [Category.ID: OrderedSet<Restaurant.ID>] = [:]

                    mutating func _reduceRelationships(_ action: some Action) {
                        switch action {
                        case let action as Actions.DidLoadNestedItem<Review.ID, Restaurant>:
                            byId.insert(item: action.item)
                            byReviewId[action.parentId] = action.item.id

                        case let action as Actions.DidLoadNestedItem<Category.ID, Restaurant>:
                            byId.insert(item: action.item)
                            byCategoryId.append(action.item.id, by: action.parentId)

                        case let action as Actions.DidLoadNestedItems<Category.ID, Restaurant>:
                            byId.insert(items: action.items)
                            byCategoryId.append(action.items.ids, by: action.parentId)

                        case let action as Actions.DidLoadNestedByParents<Category.ID, Restaurant>:
                            for (parentId, children) in action.dictionary {
                                byId.insert(items: children)
                                byCategoryId.append(children.ids, by: parentId)
                            }

                        case let action as Actions.DeleteNestedItem<Category.ID, Restaurant>:
                            byId.removeValue(forKey: action.item.id)
                            byCategoryId[action.parentId]?.remove(action.item.id)

                        default:
                            break
                        }
                    }

                    func restaurantBy(review id: Review.ID) -> Restaurant.ID? {
                        byReviewId[id]
                    }

                    func restaurantsBy(category id: Category.ID) -> [Restaurant.ID] {
                        Array(byCategoryId[id] ?? [])
                    }
                }
                """,
                macros: testMacros
            )
        #else
            throw XCTSkip("macros are only supported when running tests for the host platform")
        #endif
    }

    /// Two relationships to the same parent type — one hasOne, one hasMany with
    /// an explicit `name:` override — must still be flagged. Storage property
    /// names differ (`byProducerId` vs `coProducers`), so the existing
    /// `duplicateName` check wouldn't catch this; both would otherwise generate
    /// `Actions.DidLoadNestedItem<Producer.ID, Movie>` as a duplicate case.
    func testStorageRelationshipsDuplicateParentTypeDiagnostic() throws {
        #if canImport(UDFMacrosMacros)
            assertMacroExpansion(
                """
                @Storage(Movie.self)
                @StorageRelationships(
                    .hasOne(Producer.self),
                    .hasMany(Producer.self, name: "coProducers")
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
                            _reduceRelationships(action)
                        }
                    }

                    func movieBy(id: Movie.ID) -> Movie {
                        byId[id] ?? .empty
                    }
                }
                """,
                diagnostics: [
                    DiagnosticSpec(
                        message: "'Producer' is already used as a relationship parent type on this declaration. Two relationships to the same parent type — regardless of whether they're `.hasOne` or `.hasMany` — would generate a duplicate `Actions.DidLoadNestedItem<Producer.ID, _>` case in _reduceRelationships(_:), even if their storage property names differ via `name:`.",
                        line: 4,
                        column: 5
                    ),
                ],
                macros: testMacros
            )
        #else
            throw XCTSkip("macros are only supported when running tests for the host platform")
        #endif
    }

    /// Hand-written storage property is left untouched — macro doesn't
    /// regenerate it even though it comes from a .hasMany relationship.
    func testStorageRelationshipsHasManySkipsExistingProperty() throws {
        #if canImport(UDFMacrosMacros)
            assertMacroExpansion(
                """
                @Storage(Dish.self)
                @StorageRelationships(
                    .hasMany(Restaurant.self)
                )
                struct AllDishes: Reducible {
                    var byRestaurantId: [Restaurant.ID: OrderedSet<Dish.ID>] = [:]
                }
                """,
                expandedSource: """
                struct AllDishes: Reducible {
                    var byRestaurantId: [Restaurant.ID: OrderedSet<Dish.ID>] = [:]

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
                            _reduceRelationships(action)
                        }
                    }

                    func dishBy(id: Dish.ID) -> Dish {
                        byId[id] ?? .empty
                    }

                    mutating func _reduceRelationships(_ action: some Action) {
                        switch action {
                        case let action as Actions.DidLoadNestedItem<Restaurant.ID, Dish>:
                            byId.insert(item: action.item)
                            byRestaurantId.append(action.item.id, by: action.parentId)

                        case let action as Actions.DidLoadNestedItems<Restaurant.ID, Dish>:
                            byId.insert(items: action.items)
                            byRestaurantId.append(action.items.ids, by: action.parentId)

                        case let action as Actions.DidLoadNestedByParents<Restaurant.ID, Dish>:
                            for (parentId, children) in action.dictionary {
                                byId.insert(items: children)
                                byRestaurantId.append(children.ids, by: parentId)
                            }

                        case let action as Actions.DeleteNestedItem<Restaurant.ID, Dish>:
                            byId.removeValue(forKey: action.item.id)
                            byRestaurantId[action.parentId]?.remove(action.item.id)

                        default:
                            break
                        }
                    }

                    func dishesBy(restaurant id: Restaurant.ID) -> [Dish.ID] {
                        Array(byRestaurantId[id] ?? [])
                    }
                }
                """,
                macros: testMacros
            )
        #else
            throw XCTSkip("macros are only supported when running tests for the host platform")
        #endif
    }

    /// Hand-written accessor is left untouched — macro doesn't regenerate it.
    func testStorageRelationshipsHasManySkipsExistingAccessor() throws {
        #if canImport(UDFMacrosMacros)
            assertMacroExpansion(
                """
                @Storage(Dish.self)
                @StorageRelationships(
                    .hasMany(Restaurant.self)
                )
                struct AllDishes: Reducible {
                    func dishesBy(restaurant id: Restaurant.ID) -> [Dish.ID] {
                        Array(byRestaurantId[id] ?? [])
                    }
                }
                """,
                expandedSource: """
                struct AllDishes: Reducible {
                    func dishesBy(restaurant id: Restaurant.ID) -> [Dish.ID] {
                        Array(byRestaurantId[id] ?? [])
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
                            _reduceRelationships(action)
                        }
                    }

                    func dishBy(id: Dish.ID) -> Dish {
                        byId[id] ?? .empty
                    }

                    var byRestaurantId: [Restaurant.ID: OrderedSet<Dish.ID>] = [:]

                    mutating func _reduceRelationships(_ action: some Action) {
                        switch action {
                        case let action as Actions.DidLoadNestedItem<Restaurant.ID, Dish>:
                            byId.insert(item: action.item)
                            byRestaurantId.append(action.item.id, by: action.parentId)

                        case let action as Actions.DidLoadNestedItems<Restaurant.ID, Dish>:
                            byId.insert(items: action.items)
                            byRestaurantId.append(action.items.ids, by: action.parentId)

                        case let action as Actions.DidLoadNestedByParents<Restaurant.ID, Dish>:
                            for (parentId, children) in action.dictionary {
                                byId.insert(items: children)
                                byRestaurantId.append(children.ids, by: parentId)
                            }

                        case let action as Actions.DeleteNestedItem<Restaurant.ID, Dish>:
                            byId.removeValue(forKey: action.item.id)
                            byRestaurantId[action.parentId]?.remove(action.item.id)

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

    /// DeleteNestedItem for hasMany — full-item form only, matching the
    /// confirmed AllLabels.swift precedent. Removes the item from byId and from
    /// the OrderedSet under its parent, mirroring the .remove(_:) pattern seen
    /// in every real DeleteNestedItem usage in Librarius/Wain/FlatPlanet.
    func testStorageRelationshipsHasManyDeleteNestedItem() throws {
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
                            _reduceRelationships(action)
                        }
                    }

                    func dishBy(id: Dish.ID) -> Dish {
                        byId[id] ?? .empty
                    }

                    var byRestaurantId: [Restaurant.ID: OrderedSet<Dish.ID>] = [:]

                    mutating func _reduceRelationships(_ action: some Action) {
                        switch action {
                        case let action as Actions.DidLoadNestedItem<Restaurant.ID, Dish>:
                            byId.insert(item: action.item)
                            byRestaurantId.append(action.item.id, by: action.parentId)

                        case let action as Actions.DidLoadNestedItems<Restaurant.ID, Dish>:
                            byId.insert(items: action.items)
                            byRestaurantId.append(action.items.ids, by: action.parentId)

                        case let action as Actions.DidLoadNestedByParents<Restaurant.ID, Dish>:
                            for (parentId, children) in action.dictionary {
                                byId.insert(items: children)
                                byRestaurantId.append(children.ids, by: parentId)
                            }

                        case let action as Actions.DeleteNestedItem<Restaurant.ID, Dish>:
                            byId.removeValue(forKey: action.item.id)
                            byRestaurantId[action.parentId]?.remove(action.item.id)

                        default:
                            break
                        }
                    }

                    func dishesBy(restaurant id: Restaurant.ID) -> [Dish.ID] {
                        Array(byRestaurantId[id] ?? [])
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
