// swift-tools-version: 6.0

import PackageDescription

let package = Package(
    name: "Markdown",
    platforms: [
        .macOS(.v14)
    ],
    products: [
        .executable(name: "Markdown", targets: ["MarkdownApp"]),
        .library(name: "MarkdownCore", targets: ["MarkdownCore"])
    ],
    dependencies: [
        .package(url: "https://github.com/swiftlang/swift-markdown.git", revision: "4661b550c55abde97d14e35b89e094084669f40a")
    ],
    targets: [
        .target(
            name: "MarkdownCore",
            dependencies: [
                .product(name: "Markdown", package: "swift-markdown")
            ],
            path: "Sources/MarkdownCore"
        ),
        .executableTarget(
            name: "MarkdownApp",
            dependencies: ["MarkdownCore", "MarkdownAppSupport"],
            path: "Sources/MarkdownApp"
        ),
        .target(
            name: "MarkdownAppSupport",
            path: "Sources/MarkdownAppSupport"
        ),
        .testTarget(
            name: "MarkdownCoreTests",
            dependencies: ["MarkdownCore"],
            path: "Tests/MarkdownCoreTests"
        ),
        .testTarget(
            name: "MarkdownAppSupportTests",
            dependencies: ["MarkdownAppSupport"],
            path: "Tests/MarkdownAppSupportTests"
        )
    ]
)
