/// Compile-time-only descriptor. Never constructed or evaluated at runtime —
/// `StorageRelationshipsMacro` parses the *syntax* of each `.hasOne`/`.hasMany`
/// argument directly from the attribute's argument list. This type exists solely
/// so the `@StorageRelationships(...)` call type-checks before expansion runs.
public enum RelationshipDescriptor {
    case hasOne(Any.Type, name: String? = nil, label: String? = nil)
    case hasMany(Any.Type, name: String? = nil, label: String? = nil)
}

/// Attaches one or more storage relationships to an `@Storage`-annotated `Reducible`.
///
/// Must be combined with `@Storage(_:)` on the same declaration — `@StorageRelationships`
/// generates the relationship dictionaries and a `reduceRelationships(_:)` method, but
/// it's `@Storage`'s generated `reduce(_:)` that actually calls `reduceRelationships`.
/// Using `@StorageRelationships` without `@Storage` is a compile-time error.
///
///     @Storage(Restaurant.self)
///     @StorageRelationships(
///         .hasOne(Review.self),                                    // -> byReviewId
///         .hasOne(FortuneWheelResult.self, label: "fortuneResult"), // matches existing style
///         .hasOne(Dish.self, label: "dishID"),                      // matches existing style
///         .hasMany(Category.self)                                  // -> byCategoryId
///     )
///     struct AllRestaurants: Reducible { }
///
/// Generates, per `.hasOne` relationship:
/// - `var by<Parent>Id: [Parent.ID: Item.ID] = [:]`
/// - a `reduceRelationships(_:)` case for `Actions.DidLoadNestedItem<Parent.ID, Item>`
/// - an accessor overload `<item>By(<label>: Parent.ID) -> Item.ID?`
///
/// Generates, per `.hasMany` relationship:
/// - `var by<Parent>Id: [Parent.ID: OrderedSet<Item.ID>] = [:]` — same naming
///   scheme as `.hasOne` (no pluralization on the property: the key is still a
///   single `Parent.ID`, only the *value* is a collection)
/// - three `reduceRelationships(_:)` cases, all additive via `.append`:
///   `Actions.DidLoadNestedItem<Parent.ID, Item>`,
///   `Actions.DidLoadNestedItems<Parent.ID, Item>`, and
///   `Actions.DidLoadNestedByParents<Parent.ID, Item>`
/// - a pluralized accessor overload `<item>sBy(<label>: Parent.ID) -> [Item.ID]`
///
/// For `.hasOne`, bulk "load nested items grouped by parent" is deliberately
/// **not** generated. The single-item case (`DidLoadNestedItem`) is the only
/// realistic load pattern for a one-to-one relationship in this codebase; if a
/// `.hasOne` relationship ever needs bulk loading, add that case by hand in
/// `reduceCustom(_:)` — it still has access to `byId` / `by<Parent>Id`.
///
/// For `.hasMany`, bulk loading (`DidLoadNestedByParents`) *is* generated,
/// since batch-loading children for several parents at once is the common case
/// for one-to-many relationships (e.g. loading a page of parents and their
/// children in one response).
///
/// `name:` overrides the storage property; `label:` overrides only the accessor's
/// argument label. They're independent because the existing codebase already
/// diverges here — `by<Parent>Id` is a strict convention, but argument labels
/// (`review`, `fortuneResult`, `dishID`) are hand-picked for readability, not a
/// mechanical function of the type name.
///
/// Bundling relationships into one variadic call (rather than repeating
/// `@StorageRelationship(...)` per relationship) is deliberate: only within a
/// single macro expansion can name collisions between two relationships to the
/// same parent type be caught as a clear diagnostic instead of a silent
/// duplicate/overwrite — this applies across `.hasOne` and `.hasMany` alike,
/// since two relationships to the same parent type generate the same
/// `Actions.DidLoadNestedItem<Parent.ID, _>` case regardless of kind.
@attached(member, names: arbitrary)
public macro StorageRelationships(_ relationships: RelationshipDescriptor...) =
    #externalMacro(module: "UDFMacrosMacros", type: "StorageRelationshipsMacro")
