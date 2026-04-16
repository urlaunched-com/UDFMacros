// The Swift Programming Language
// https://docs.swift.org/swift-book

@attached(extension, conformances: Equatable, names: named(==))
public macro AutoEquatable() = #externalMacro(module: "UDFMacrosMacros", type: "AutoEquatableMacro")

@attached(extension, conformances: Hashable, names: arbitrary)
public macro AutoHashable() = #externalMacro(module: "UDFMacrosMacros", type: "AutoHashableMacro")

@attached(peer)
public macro SensitiveField() = #externalMacro(module: "UDFMacrosMacros", type: "SensitiveFieldMacro")

@attached(extension, conformances: CustomStringConvertible, SensitiveDataRepresentable,  names: named(description), named(maskedDescription), named(plainDescription))
public macro SensitiveAction() = #externalMacro(module: "UDFMacrosMacros", type: "SensitiveActionMacro")
