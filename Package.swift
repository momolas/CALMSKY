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
        .library(name: "AstronomyKit", targets: ["AstronomyKit"]),
        .library(name: "SwiftAstronomy", targets: ["AstronomyKit"]) // Alias de rétrocompatibilité
    ],
    targets: [
        .target(
            name: "AstronomyKit",
            path: "Sources/AstronomyKit",
            resources: [
                .process("AstronomyKit.docc")
            ],
            swiftSettings: [
                .swiftLanguageMode(.v6)
            ],
            linkerSettings: [
                .linkedFramework("Accelerate", .when(platforms: [.macOS, .iOS, .tvOS, .watchOS, .visionOS]))
            ]
        ),
        .testTarget(
            name: "AstronomyKitTests",
            dependencies: ["AstronomyKit"],
            path: "Tests/AstronomyKitTests",
            swiftSettings: [
                .swiftLanguageMode(.v6)
            ],
            linkerSettings: [
                .linkedFramework("Accelerate", .when(platforms: [.macOS, .iOS, .tvOS, .watchOS, .visionOS]))
            ]
        )
    ]
)
