// swift-tools-version: 6.0

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
            targets: ["Papyrus"]
        )
    ],
    dependencies: [.package(url: "https://github.com/apple/swift-async-algorithms", from: "1.1.1")],
    targets: [
        .target(
            name: "Papyrus",
            dependencies: [
                .product(name: "AsyncAlgorithms", package: "swift-async-algorithms")
            ]
        ),
        .testTarget(
            name: "Unit",
            dependencies: ["Papyrus"],
            exclude: ["Supporting Files/Unit.xctestplan"]
        ),
        .testTarget(
            name: "Performance",
            dependencies: ["Papyrus"],
            exclude: ["Supporting Files/Performance.xctestplan"]
        )
    ]
)
