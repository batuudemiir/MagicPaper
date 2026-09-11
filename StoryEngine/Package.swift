// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "StoryEngine",
    platforms: [
        .iOS(.v15),
        .macOS(.v13)
    ],
    products: [
        .library(name: "StoryEngine", targets: ["StoryEngine"]),
        .library(name: "CharacterEngine", targets: ["CharacterEngine"]),
        .library(name: "VisualSystem", targets: ["VisualSystem"]),
        .library(name: "EngineFoundation", targets: ["EngineFoundation"])
    ],
    targets: [
        // Primitives every other target shares: semantic versioning and the
        // deterministic hashing that fingerprints and seeds depend on.
        .target(name: "EngineFoundation"),

        // Identity domain. Owns everything the engine is allowed to know about
        // a character's appearance. Depends on nothing.
        .target(
            name: "CharacterEngine",
            dependencies: ["EngineFoundation"],
            resources: [.process("Resources")]
        ),

        // Design system as data. Compiles style/composition/palette/typography
        // presets into the constraint set an ImageProvider receives.
        .target(
            name: "VisualSystem",
            dependencies: ["EngineFoundation", "CharacterEngine"],
            resources: [.process("Resources")]
        ),

        // The story engine itself. Vendor-free: no UIKit, no SwiftUI, no SDKs.
        .target(
            name: "StoryEngine",
            dependencies: ["EngineFoundation", "CharacterEngine", "VisualSystem"],
            resources: [.process("Resources")]
        ),

        .testTarget(name: "EngineFoundationTests", dependencies: ["EngineFoundation"]),
        .testTarget(name: "CharacterEngineTests", dependencies: ["CharacterEngine"]),
        .testTarget(name: "VisualSystemTests", dependencies: ["VisualSystem", "CharacterEngine", "EngineFoundation"]),
        .testTarget(
            name: "StoryEngineTests",
            dependencies: ["StoryEngine", "CharacterEngine", "VisualSystem", "EngineFoundation"],
            // Golden fixtures are read from the source tree via #filePath, not
            // from a bundle: a test that regenerates them has to write back to
            // the file a human will review in the diff.
            exclude: ["Fixtures"]
        )
    ]
)
