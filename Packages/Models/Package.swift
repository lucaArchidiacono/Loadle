// swift-tools-version: 5.9
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "Models",
    platforms: [.iOS(.v17), .macOS(.v14), .visionOS(.v1)],
    products: [
        // Products define the executables and libraries a package produces, making them visible to other packages.
        .library(
            name: "Models",
            targets: ["Models"]
        ),
    ],
    dependencies: [
        .package(path: "../Fundamentals"),
        .package(path: "../Generator"),
    ],
    targets: [
        // Targets are the basic building blocks of a package, defining a module or a test suite.
        // Targets can depend on other targets in this package and products from dependencies.
        .target(
            name: "Models",
            dependencies: [
                .product(name: "Generator", package: "Generator"),
                .product(name: "Fundamentals", package: "Fundamentals"),
            ],
            resources: [
                .process("Resources/JengaInstructionsSkit.mp3"),
            ]
        ),
        .testTarget(
            name: "ModelsTests",
            dependencies: ["Models"]
        ),
    ]
)
