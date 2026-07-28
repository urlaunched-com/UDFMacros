// The Swift Programming Language
// https://docs.swift.org/swift-book

@attached(extension, conformances: Equatable, names: named(==))
public macro AutoEquatable() = #externalMacro(module: "UDFMacrosMacros", type: "AutoEquatableMacro")

@attached(extension, conformances: Hashable, names: arbitrary)
public macro AutoHashable() = #externalMacro(module: "UDFMacrosMacros", type: "AutoHashableMacro")

@attached(peer)
public macro SensitiveField() = #externalMacro(module: "UDFMacrosMacros", type: "SensitiveFieldMacro")

@attached(extension, conformances: CustomStringConvertible, SensitiveDataRepresentable, names: named(description), named(maskedDescription), named(plainDescription))
public macro SensitiveData(option: SensitiveDataOption? = nil) = #externalMacro(module: "UDFMacrosMacros", type: "SensitiveDataMacro")

/// Generates the `byId` storage dictionary, the standard CRUD `reduce`
/// handling (`DidLoadItems`, `DidLoadItem`, `DidUpdateItem`, `DeleteItem`),
/// and a `<lowerCamelCase(Item)>By(id:)` convenience accessor (e.g. `dishBy(id:)`
/// for `Dish`) that most `Reducible` "AllX" storages repeat verbatim.
///
/// The accessor falls back to `Item.empty` — the attached `Item` type must
/// declare a static `empty` member itself (there's no protocol backing this
/// in the codebase, so it isn't enforced at the `@Storage` declaration; a
/// missing `.empty` surfaces as a compile error inside the generated
/// accessor instead).
///
/// If `byId`, `reduce`, and/or the accessor are already declared in the
/// attached struct, the macro leaves that member alone and only fills in
/// what's missing — this is the escape hatch for a storage that needs an
/// extra action case (e.g. `DidToggleFavorite<Movie>`) alongside the
/// standard four: write your own `reduce` with the extra case, and the
/// macro won't try to generate a conflicting one.
@attached(member, names: named(byId), named(reduce), arbitrary)
public macro Storage<Item: Identifiable>(_ type: Item.Type) = #externalMacro(module: "UDFMacrosMacros", type: "StorageMacro")
