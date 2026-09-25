// swift-tools-version: 6.0
import PackageDescription

let package = Package(
    name: "AstronomyKit",
    defaultLocalization: "en",
    platforms: [
        .macOS(.v15),
        .iOS(.v18),
        .tvOS(.v18),
        .watchOS(.v11),
        .visionOS(.v2)
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
                .linkedFramework("Accelerate")
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
                .linkedFramework("Accelerate")
            ]
        )
    ]
)
