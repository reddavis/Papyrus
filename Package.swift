// swift-tools-version: 5.7
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "Papyrus",
    platforms: [
        .iOS(.v16),
        .macOS(.v13),
        .watchOS(.v7),
        .tvOS(.v16)
    ],
    products: [
        .library(
            name: "Papyrus",
            targets: ["Papyrus"]),
    ],
    dependencies: [],
    targets: [
        .target(name: "Papyrus"),
        .testTarget(
            name: "Unit",
            dependencies: ["Papyrus"],
            exclude: ["Performance/Supporting Files/Unit.xctestplan"]
        ),
        .testTarget(
            name: "Performance",
            dependencies: ["Papyrus"],
            exclude: ["Performance/Supporting Files/Performance.xctestplan"]
        ),
    ]
)
