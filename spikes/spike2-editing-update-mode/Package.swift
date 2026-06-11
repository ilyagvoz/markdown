// swift-tools-version: 6.0

import PackageDescription

let package = Package(
    name: "EditingUpdateModeSpike",
    platforms: [
        .macOS(.v14)
    ],
    products: [
        .library(name: "EditingSpike", targets: ["EditingSpike"])
    ],
    targets: [
        .target(
            name: "EditingSpike",
            path: "Sources/EditingSpike"
        ),
        .testTarget(
            name: "EditingSpikeTests",
            dependencies: ["EditingSpike"],
            path: "Tests/EditingSpikeTests"
        )
    ]
)
