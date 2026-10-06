// swift-tools-version: 5.9
import PackageDescription

// Batuhan's tool for publishing remote content (FAZ 15). Built against the
// engine itself, so a package is validated by the very loader and integrity
// check the app runs — not by a second copy of the rules.
let package = Package(
    name: "ContentPublisher",
    platforms: [.macOS(.v13)],
    dependencies: [.package(path: "../../StoryEngine")],
    targets: [
        .target(name: "PublisherKit", dependencies: [.product(name: "StoryEngine", package: "StoryEngine")]),
        .executableTarget(name: "content-publisher", dependencies: ["PublisherKit"]),
        .testTarget(name: "PublisherKitTests", dependencies: ["PublisherKit"]),
    ]
)
