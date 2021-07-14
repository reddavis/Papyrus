// swift-tools-version:5.3
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription


let package = Package(
    name: "Papyrus",
    platforms: [
        .iOS("15.0"),
        .macOS("12.0")
    ],
    products: [
        .library(
            name: "Papyrus",
            targets: ["Papyrus"]),
    ],
    targets: [
        .target(
            name: "Papyrus",
            path: "Papyrus",
            exclude: ["Supporting Files/Info.plist"]),
        .testTarget(
            name: "PapyrusTests",
            dependencies: ["Papyrus"],
            path: "PapyrusTests"),
    ]
)
