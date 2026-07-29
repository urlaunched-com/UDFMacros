/// Compile-time-only descriptor. Never constructed or evaluated at runtime —
/// `StorageRelationshipsMacro` parses the *syntax* of each `.hasOne` argument
/// directly from the attribute's argument list. This type exists solely so
/// the `@StorageRelationships(...)` call type-checks before expansion runs.
///
/// `.hasMany` is intentionally not implemented yet — using it is a compile-time
/// macro error, not silently-wrong generated code.
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
///         .hasOne(Dish.self, label: "dishID")                       // matches existing style
///     )
///     struct AllRestaurants: Reducible { }
///
/// Generates, per relationship:
/// - `var by<Parent>Id: [Parent.ID: Item.ID] = [:]`
/// - a `reduceRelationships(_:)` case for `Actions.DidLoadNestedItem<Parent.ID, Item>`
/// - an accessor overload `<item>By(<label>: Parent.ID) -> Item.ID?`
///
/// Bulk "load nested items grouped by parent" is deliberately **not** generated.
/// The action used for that in this codebase (`DidLoadNestedItemByParents`) is
/// defined at the app level, not in UDFMacros/UDF — its name and shape aren't
/// standardized across apps, so the macro can't safely reference it. Add that
/// case by hand in `reduceCustom(_:)` if a relationship needs it; it still has
/// access to `byId` / `by<Parent>Id`.
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
/// duplicate/overwrite.
@attached(member, names: arbitrary)
public macro StorageRelationships(_ relationships: RelationshipDescriptor...) =
    #externalMacro(module: "UDFMacrosMacros", type: "StorageRelationshipsMacro")
