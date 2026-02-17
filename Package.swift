// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "MacAutoBackground",
    platforms: [
        .macOS(.v12)
    ],
    products: [
        .executable(name: "MacAutoBackground", targets: ["MacAutoBackground"])
    ],
    dependencies: [],
    targets: [
        .executableTarget(
            name: "MacAutoBackground",
            dependencies: [],
            path: "Sources/MacAutoBackground",
            resources: [
                .process("Resources")
            ]
        )
    ]
)
