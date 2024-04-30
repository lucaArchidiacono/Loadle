// swift-tools-version: 5.9
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "Environments",
    platforms: [.iOS(.v17), .macOS(.v14), .visionOS(.v1)],
    products: [
        // Products define the executables and libraries a package produces, making them visible to other packages.
        .library(
            name: "Environments",
            targets: ["Environments"]
        ),
    ],
    dependencies: [
        .package(path: "../Logger"),
        .package(path: "../REST"),
        .package(path: "../Constants"),
        .package(path: "../Models"),
        .package(path: "../LocalStorage"),
        .package(url: "https://github.com/dfed/swift-async-queue", from: "0.5.0"),
    ],
    targets: [
        // Targets are the basic building blocks of a package, defining a module or a test suite.
        // Targets can depend on other targets in this package and products from dependencies.
        .target(
            name: "Environments",
            dependencies: [
                .product(name: "Logger", package: "Logger"),
                .product(name: "REST", package: "REST"),
                .product(name: "Constants", package: "Constants"),
                .product(name: "Models", package: "Models"),
                .product(name: "LocalStorage", package: "LocalStorage"),
                .product(name: "AsyncQueue", package: "swift-async-queue"),
                //				.product(name: "SQLite", package: "SQLite")
            ]
        ),
        .testTarget(
            name: "EnvironmentsTests",
            dependencies: ["Environments"]
        ),
    ]
)
