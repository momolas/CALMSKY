// swift-tools-version: 6.0
import PackageDescription

let package = Package(
    name: "AstronomyKit",
    defaultLocalization: "en",
    platforms: [
        .macOS(.v10_15),
        .iOS(.v13),
        .tvOS(.v12),
        .watchOS(.v7)
    ],
    products: [
        // The C++ astronomical algorithms library by J.P. Naughter
        .library(name: "AAplus", targets: ["AAplus"]),
        // The Swift wrapper API
        .library(name: "AstronomyKit", targets: ["AstronomyKit"]),
        .library(name: "SwiftAstronomy", targets: ["AstronomyKit"]) // Alias de rétrocompatibilité
    ],
    targets: [
        // MARK: - C++ Core
        .target(
            name: "AAplus",
            path: "Sources/AA+",
            publicHeadersPath: ".",
            cxxSettings: [
                .headerSearchPath(".")
            ]
        ),

        // MARK: - Swift API
        .target(
            name: "AstronomyKit",
            dependencies: ["AAplus"],
            path: "Sources/SwiftAstronomy",
            resources: [
                .process("SwiftAstronomy.docc")
            ],
            swiftSettings: [
                .interoperabilityMode(.Cxx),
                .swiftLanguageMode(.v6)
            ]
        ),
        .testTarget(
            name: "SwiftAstronomyTests",
            dependencies: ["AstronomyKit", "AAplus"],
            path: "Tests/SwiftAstronomyTests",
            swiftSettings: [
                .interoperabilityMode(.Cxx),
                .swiftLanguageMode(.v6)
            ],
            linkerSettings: [
                .linkedLibrary("c++")
            ]
        )
    ],
    cxxLanguageStandard: .cxx17
)
