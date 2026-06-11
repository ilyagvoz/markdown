// swift-tools-version: 6.0

import PackageDescription

let package = Package(
    name: "NativeWebViewEditorSpike",
    platforms: [
        .macOS(.v14)
    ],
    products: [
        .executable(name: "NativeWebViewEditorSpike", targets: ["NativeWebViewEditorSpike"]),
        .library(name: "NativeWebViewEditorSpikeSupport", targets: ["NativeWebViewEditorSpikeSupport"])
    ],
    targets: [
        .target(
            name: "NativeWebViewEditorSpikeSupport",
            path: "Sources/NativeWebViewEditorSpikeSupport"
        ),
        .executableTarget(
            name: "NativeWebViewEditorSpike",
            dependencies: ["NativeWebViewEditorSpikeSupport"],
            path: "Sources/NativeWebViewEditorSpike",
            resources: [
                .copy("Resources")
            ]
        ),
        .testTarget(
            name: "NativeWebViewEditorSpikeSupportTests",
            dependencies: ["NativeWebViewEditorSpikeSupport"],
            path: "Tests/NativeWebViewEditorSpikeSupportTests"
        )
    ]
)
