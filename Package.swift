// swift-tools-version: 6.0
import PackageDescription

let package = Package(
    name: "SwiftBaseball",
    platforms: [
        .macOS(.v14),
        .iOS(.v17),
        .tvOS(.v17),
        .watchOS(.v10),
        .visionOS(.v1)
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
    ],
    swiftLanguageModes: [.v6]
)
