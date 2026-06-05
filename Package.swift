// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "MonkMode",
    platforms: [
        .macOS(.v13)
    ],
    targets: [
        .executableTarget(
            name: "MonkMode",
            path: "Sources/MonkMode",
            exclude: ["Resources"]
        )
    ]
)
