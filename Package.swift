// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "BongoCatMenubar",
    platforms: [.macOS(.v13)],
    targets: [
        // Pure logic (key map, animation state machine, icon lookup), unit-tested.
        .target(
            name: "BongoCatCore",
            path: "Sources/BongoCatCore"
        ),
        // App shell: NSApplication, status item, menu, CGEvent tap.
        .executableTarget(
            name: "BongoCatMenubar",
            dependencies: ["BongoCatCore"],
            path: "Sources/BongoCatMenubar"
        ),
    ]
)
