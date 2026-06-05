// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "TimeBlocker",
    platforms: [
        .macOS(.v13)
    ],
    targets: [
        .executableTarget(
            name: "TimeBlocker",
            path: "Sources/TimeBlocker",
            exclude: ["Resources"]
        )
    ]
)
