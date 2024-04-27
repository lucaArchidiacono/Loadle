// swift-tools-version: 5.9
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "REST",
    platforms: [.iOS(.v17), .macOS(.v14), .visionOS(.v1)],
    products: [
        // Products define the executables and libraries a package produces, making them visible to other packages.
        .library(
            name: "REST",
            targets: ["REST"]
        ),
    ],
    dependencies: [
        .package(path: "../Logger"),
		.package(path: "../Fundamentals"),
    ],
    targets: [
        // Targets are the basic building blocks of a package, defining a module or a test suite.
        // Targets can depend on other targets in this package and products from dependencies.
        .target(
            name: "REST",
            dependencies: [
                .product(name: "Logger", package: "Logger"),
				.product(name: "Fundamentals", package: "Fundamentals"),
            ]
        ),
        .testTarget(
            name: "RESTTests",
            dependencies: ["REST"]
        ),
    ]
)
