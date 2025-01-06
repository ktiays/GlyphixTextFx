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
        ),
        .library(
            name: "NumericLabel",
            targets: ["NumericLabel"]
        ),
    ],
    dependencies: [
        .package(url: "https://github.com/ktiays/Respring", from: "1.0.0"),
        .package(url: "https://github.com/Lakr233/MSDisplayLink", from: "2.0.3"),
    ],
    targets: [
        .target(
            name: "NumericTransitionLabel",
            dependencies: ["Respring", "MSDisplayLink"]
        ),
        .target(
            name: "NumericLabel", dependencies: ["NumericTransitionLabel"]
        ),
    ]
)
