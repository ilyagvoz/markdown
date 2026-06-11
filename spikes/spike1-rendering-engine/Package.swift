// swift-tools-version: 6.0

import PackageDescription

let package = Package(
    name: "RenderingEngineSpike",
    platforms: [
        .macOS(.v14)
    ],
    products: [
        .executable(name: "rendering-spike", targets: ["RenderingSpike"])
    ],
    dependencies: [
        .package(url: "https://github.com/swiftlang/swift-markdown.git", branch: "main")
    ],
    targets: [
        .executableTarget(
            name: "RenderingSpike",
            dependencies: [
                .product(name: "Markdown", package: "swift-markdown")
            ],
            path: "Sources/RenderingSpike"
        )
    ]
)
