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
        .package(url: "https://github.com/Lakr233/MSDisplayLink", from: "2.0.8"),
        .package(url: "https://github.com/ktiays/With", from: "1.2.0"),
    ],
    targets: [
        .target(name: "GTFHook"),
        .target(
            name: "GlyphixTextFx",
            dependencies: ["Respring", "MSDisplayLink", "GTFHook", "With"]
        ),
    ]
)
