// swift-tools-version: 5.5
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "MarkdownToAttributedString",
    products: [
        .library(
            name: "MarkdownToAttributedString",
            targets: ["MarkdownToAttributedString"]),
    ],
    dependencies: [
        .package(
            url: "https://github.com/swiftlang/swift-markdown.git",
            branch: "main"),
    ],
    targets: [
        .target(
            name: "MarkdownToAttributedString",
            dependencies: [
                .product(name: "Markdown", package: "swift-markdown"),
            ]
        ),
        .testTarget(
            name: "MarkdownToAttributedStringTests",
            dependencies: ["MarkdownToAttributedString"]),
    ]
)
