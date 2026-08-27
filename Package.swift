// swift-tools-version: 6.0
// The swift-tools-version declares the minimum version of Swift required to build this package.

import CompilerPluginSupport
import PackageDescription

let package = Package(
    name: "UDFMacros",
    // Raised to match UDF 2.0.0's own minimums (macOS 13 / iOS 16) now that
    // UDFMacros depends on it directly for @Storage's Storage conformance.
    platforms: [.macOS(.v13), .iOS(.v16), .tvOS(.v16), .watchOS(.v9), .macCatalyst(.v16)],
    products: [
        // Products define the executables and libraries a package produces, making them visible to other packages.
        .library(
            name: "UDFMacros",
            targets: ["UDFMacros"]
        ),
        .executable(
            name: "UDFMacrosClient",
            targets: ["UDFMacrosClient"]
        ),
    ],
    dependencies: [
        .package(url: "https://github.com/swiftlang/swift-syntax.git", from: "600.0.0-latest"),
        // Pinned to the 2.0.0 alpha so @Storage can auto-conform attached
        // structs to UDF's new `Storage` protocol (needed for modularization).
        // Move this to a proper `from:` release requirement once UDF 2.0.0 ships.
        .package(url: "https://github.com/Maks-Jago/SwiftUI-UDF.git", exact: "2.0.0-alpha.2"),
    ],
    targets: [
        // Targets are the basic building blocks of a package, defining a module or a test suite.
        // Targets can depend on other targets in this package and products from dependencies.
        // Macro implementation that performs the source transformation of a macro.
        .macro(
            name: "UDFMacrosMacros",
            dependencies: [
                .product(name: "SwiftSyntaxMacros", package: "swift-syntax"),
                .product(name: "SwiftCompilerPlugin", package: "swift-syntax"),
                .product(name: "SwiftDiagnostics", package: "swift-syntax"),
            ]
        ),

        // Library that exposes a macro as part of its API, which is used in client programs.
        // Depends on UDF directly because `@Storage`'s `@attached(extension, conformances: Storage, ...)`
        // must resolve the real `Storage` protocol type at this target's compile time.
        .target(
            name: "UDFMacros",
            dependencies: [
                "UDFMacrosMacros",
                .product(name: "UDF", package: "SwiftUI-UDF"),
            ]
        ),

        // A client of the library, which is able to use the macro in its own code.
        .executableTarget(name: "UDFMacrosClient", dependencies: ["UDFMacros"]),

        // A test target used to develop the macro implementation.
        .testTarget(
            name: "UDFMacrosTests",
            dependencies: [
                "UDFMacrosMacros",
                .product(name: "SwiftSyntaxMacrosTestSupport", package: "swift-syntax"),
            ]
        ),
    ]
)
