// swift-tools-version: 5.9
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "GlyphixTextFx",
    platforms: [
        .macOS(.v11),
        .iOS(.v13),
        .watchOS(.v5),
        .tvOS(.v13),
    ],
    products: [
        .library(
            name: "GlyphixTextFx",
            targets: ["GlyphixTextFx"]
        )
    ],
    dependencies: [
        .package(url: "https://github.com/ktiays/Respring", from: "1.0.0"),
        .package(url: "https://github.com/unixzii/Choreographer", from: "0.1.0"),
        .package(url: "https://github.com/ktiays/With", from: "1.2.0"),
    ],
    targets: [
        .target(name: "GlyphixTypesetter", dependencies: ["With"]),
        .target(name: "GlyphixHook"),
        .target(
            name: "GlyphixTextFx",
            dependencies: ["Respring", "Choreographer", "With", "GlyphixTypesetter", "GlyphixHook"]
        ),
    ]
)
