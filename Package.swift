// swift-tools-version: 5.9
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "NumericTransitionLabel",
    platforms: [
        .macOS(.v14),
        .iOS(.v17),
        .watchOS(.v10),
        .tvOS(.v17),
    ],
    products: [
        .library(
            name: "NumericTransitionLabel",
            targets: ["NumericTransitionLabel"]
        )
    ],
    targets: [
        .target(
            name: "NumericTransitionLabel"
        )
    ]
)
