// swift-tools-version: 5.7
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "Papyrus",
    platforms: [
        .iOS(.v15),
        .macOS(.v12),
        .watchOS(.v6),
        .tvOS(.v15)
    ],
    products: [
        .library(
            name: "Papyrus",
            targets: ["Papyrus"]),
    ],
    dependencies: [
        .package(url: "https://github.com/reddavis/Asynchrone", from: "0.21.0"),
    ],
    targets: [
        .target(
            name: "Papyrus",
            dependencies: []),
        .testTarget(
            name: "PapyrusTests",
            dependencies: ["Papyrus", "Asynchrone"]
        ),
    ]
)
