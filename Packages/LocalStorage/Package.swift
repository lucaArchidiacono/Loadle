// swift-tools-version: 5.9
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "LocalStorage",
    platforms: [.iOS(.v17), .macOS(.v14), .visionOS(.v1)],
    products: [
        // Products define the executables and libraries a package produces, making them visible to other packages.
        .library(
            name: "LocalStorage",
            targets: ["LocalStorage"]
        ),
    ],
    dependencies: [
        .package(path: "../Logger"),
        .package(path: "../Fundamentals"),
        .package(path: "../Models"),
        .package(url: "https://github.com/mergesort/Bodega.git", .upToNextMajor(from: "2.1.2")),
    ],
    targets: [
        // Targets are the basic building blocks of a package, defining a module or a test suite.
        // Targets can depend on other targets in this package and products from dependencies.
        .target(
            name: "LocalStorage",
            dependencies: [
                .product(name: "Logger", package: "Logger"),
                .product(name: "Fundamentals", package: "Fundamentals"),
                .product(name: "Models", package: "Models"),
                .product(name: "Bodega", package: "Bodega"),
            ]
        ),
        .testTarget(
            name: "LocalStorageTests",
            dependencies: ["LocalStorage"]
        ),
    ]
)
