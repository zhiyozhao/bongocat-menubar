// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "BongoCatMenubar",
    platforms: [.macOS(.v13)],
    targets: [
        .executableTarget(
            name: "BongoCatMenubar",
            path: "Sources/BongoCatMenubar"
        )
    ]
)
