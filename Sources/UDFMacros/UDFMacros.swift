// The Swift Programming Language
// https://docs.swift.org/swift-book

/// - Parameter ignoringTypeNames: Names of additional closure type aliases (e.g. a custom
///   `typealias MyClosure = (Int) -> Void`) that should be excluded from the generated equality
///   check, just like direct closure types are. SwiftSyntax cannot resolve typealiases during
///   macro expansion, so any alias not in the built-in `Command`/`CommandWith...` family must be
///   listed explicitly here:
///   ```swift
///   @AutoEquatable(ignoringTypeNames: ["MyClosure"])
///   enum Route {
///       case details(id: String, action: MyClosure)
///   }
///   ```
@attached(extension, conformances: Equatable, names: named(==))
public macro AutoEquatable(ignoringTypeNames: [String] = []) = #externalMacro(module: "UDFMacrosMacros", type: "AutoEquatableMacro")

/// - Parameter ignoringTypeNames: Same as `AutoEquatable(ignoringTypeNames:)` - additional
///   closure type-alias names to exclude from both the generated equality check and hashing.
@attached(extension, conformances: Hashable, names: arbitrary)
public macro AutoHashable(ignoringTypeNames: [String] = []) = #externalMacro(module: "UDFMacrosMacros", type: "AutoHashableMacro")
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
/// what's missing.
///
/// **Custom actions:** if you declare a `mutating func reduceCustom(_ action:
/// some Action)`, the generated `reduce`'s `default:` case calls it instead
/// of `break` — write your bespoke cases there (e.g. `DidLoadPopularDishes`,
/// `DidDislikeDish`) without needing to hand-write the whole `reduce`.
/// If you don't declare `reduceCustom`, `default:` stays `break` exactly as
/// before. For the rarer case where you need to override one of the
/// standard four cases itself, write the full `reduce` by hand — the macro
/// detects that and won't generate a conflicting one.
@attached(member, names: named(byId), named(reduce), arbitrary)
public macro Storage<Item: Identifiable>(_ type: Item.Type) = #externalMacro(module: "UDFMacrosMacros", type: "StorageMacro")
