// swift-tools-version:5.5
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription


let package = Package(
    name: "Papyrus",
    platforms: [
        .iOS(.v13),
        .macOS(.v10_15),
        .tvOS(.v13),
        .watchOS(.v6)
    ],
    products: [
        .library(
            name: "Papyrus",
            targets: ["Papyrus"]
        )
    ],
    targets: [
        .target(
            name: "Papyrus",
            path: "Papyrus"
        ),
        .testTarget(
            name: "PapyrusTests",
            dependencies: ["Papyrus"],
            path: "PapyrusTests",
            exclude: ["Supporting Files/Info.plist"]
        )
    ]
)
