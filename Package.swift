// swift-tools-version: 5.9
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "NumericTransitionLabel",
    platforms: [
        .macOS(.v11),
        .iOS(.v13),
        .watchOS(.v5),
        .tvOS(.v13),
    ],
    products: [
        .library(
            name: "NumericTransitionLabel",
            targets: ["NumericTransitionLabel"]
        )
    ],
    dependencies: [
        .package(url: "https://github.com/ktiays/Respring", branch: "main"),
    ],
    targets: [
        .target(
            name: "NumericTransitionLabel",
            dependencies: ["Respring"]
        )
    ]
)
