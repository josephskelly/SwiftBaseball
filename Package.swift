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
        .library(name: "SwiftBaseball", targets: ["SwiftBaseball"]),
        .executable(name: "baseball-cli", targets: ["baseball-cli"])
    ],
    targets: [
        .target(
            name: "SwiftBaseball",
            path: "Sources/SwiftBaseball"
        ),
        .target(
            name: "CLISupport",
            path: "Sources/CLISupport"
        ),
        .executableTarget(
            name: "baseball-cli",
            dependencies: ["SwiftBaseball", "CLISupport"],
            path: "Sources/CLI"
        ),
        .testTarget(
            name: "SwiftBaseballTests",
            dependencies: ["SwiftBaseball", "CLISupport"],
            path: "Tests/SwiftBaseballTests",
            resources: [.copy("Fixtures")]
        )
    ]
)
