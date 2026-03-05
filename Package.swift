// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "SwiftBaseball",
    platforms: [
        .macOS(.v13),
        .iOS(.v16),
        .tvOS(.v16),
        .watchOS(.v9)
    ],
    products: [
        .library(name: "SwiftBaseball", targets: ["SwiftBaseball"])
    ],
    targets: [
        .target(
            name: "SwiftBaseball",
            path: "Sources/SwiftBaseball"
        ),
        .testTarget(
            name: "SwiftBaseballTests",
            dependencies: ["SwiftBaseball"],
            path: "Tests/SwiftBaseballTests",
            resources: [.copy("Fixtures")]
        )
    ]
)
