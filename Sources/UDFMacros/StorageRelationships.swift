/// Describes relationships that should be generated for a storage.
///
/// `StorageRelationshipsMacro` parses the syntax of each descriptor at compile time
/// and uses it to generate relationship properties, reducer handling, and lookup methods.
///
/// This type exists only to make `@StorageRelationships(...)` type-check before
/// macro expansion and is not intended to be constructed or evaluated at runtime.
public enum RelationshipDescriptor {
    /// Declares a to-one relationship with another storage item type.
    ///
    /// - Parameters:
    ///   - type: The related storage item type.
    ///   - propertyName: Overrides the name of the generated relationship property.
    ///     For example, `"byFortuneResultId"` generates a property with that name.
    ///   - argumentLabel: Overrides the argument label used by the generated
    ///     relationship lookup method. By default, it is the related type name
    ///     followed by `ID`; for example, `"reviewID"` generates a lookup such
    ///     as `restaurantBy(reviewID:)`.
    case hasOne(
        Any.Type,
        propertyName: String? = nil,
        argumentLabel: String? = nil
    )

    /// Declares a to-many relationship with another storage item type.
    ///
    /// - Parameters:
    ///   - type: The related storage item type.
    ///   - propertyName: Overrides the name of the generated relationship property.
    ///     For example, `"byCategoryId"` generates a property with that name.
    ///   - argumentLabel: Overrides the argument label used by the generated
    ///     relationship lookup method. By default, it is the related type name
    ///     followed by `ID`; for example, `"categoryID"` generates a lookup
    ///     such as `restaurantIDsBy(categoryID:)`.
    case hasMany(
        Any.Type,
        propertyName: String? = nil,
        argumentLabel: String? = nil
    )
}

/// Attaches one or more storage relationships to an `@Storage`-annotated `Reducible`.
///
/// Must be combined with `@Storage(_:)` on the same declaration — `@StorageRelationships`
/// generates the relationship dictionaries and a `_reduceRelationships(_:)` method, but
/// it's `@Storage`'s generated `reduce(_:)` that actually calls `_reduceRelationships`.
/// Using `@StorageRelationships` without `@Storage` is a compile-time error.
///
///     @Storage(Restaurant.self)
///     @StorageRelationships(
///         .hasOne(Review.self),                                    // -> byReviewId
///         .hasOne(FortuneWheelResult.self, propertyName: "byFortuneResultId"),
///         .hasOne(Dish.self),
///         .hasMany(Category.self)                                  // -> byCategoryId
///     )
///     struct AllRestaurants: Reducible { }
///
/// Generates, per `.hasOne` relationship:
/// - `var by<Parent>Id: [Parent.ID: Item.ID] = [:]`
/// - a `_reduceRelationships(_:)` case for `Actions.DidLoadNestedItem<Parent.ID, Item>`
/// - an accessor overload `<item>By(<parent>ID: Parent.ID) -> Item.ID?`
///
/// Generates, per `.hasMany` relationship:
/// - `var by<Parent>Id: [Parent.ID: OrderedSet<Item.ID>] = [:]` — same naming
///   scheme as `.hasOne` (no pluralization on the property: the key is still a
///   single `Parent.ID`, only the *value* is a collection)
/// - three `_reduceRelationships(_:)` cases, all additive via `.append`:
///   `Actions.DidLoadNestedItem<Parent.ID, Item>`,
///   `Actions.DidLoadNestedItems<Parent.ID, Item>`, and
///   `Actions.DidLoadNestedByParents<Parent.ID, Item>`
/// - an accessor overload `<item>IDsBy(<parent>ID: Parent.ID) -> [Item.ID]`, where
///   `IDs` uses a capitalized initialism and a lowercase plural `s`
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
/// `propertyName:` overrides the storage property; `argumentLabel:` overrides only
/// the accessor's argument label. They're independent because the existing codebase
/// already diverges here — `by<Parent>Id` is a strict convention, but argument
/// labels can be hand-picked for readability, while the default is the related
/// type name followed by `ID`.
///
/// The `_reduceRelationships` / `_` prefix marks it as a generated, reserved
/// member — matching the convention already used elsewhere in this codebase
/// for internal/framework-generated members (e.g. `_OnContainerDidLoad`,
/// `_BindableAction`). It signals "generated, don't hand-write a method with
/// this exact name" the same way those do.
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
