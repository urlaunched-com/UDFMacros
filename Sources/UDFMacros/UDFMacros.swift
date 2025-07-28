// The Swift Programming Language
// https://docs.swift.org/swift-book

@attached(extension, conformances: Equatable, names: named(==))
public macro AutoEquatable() = #externalMacro(module: "UDFMacrosMacros", type: "AutoEquatableMacro")
