// swift-tools-version: 5.9
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "HDWalletKit",
    products: [
        // Products define the executables and libraries a package produces, making them visible to other packages.
        .library(
            name: "HDWalletKit",
            targets: ["HDWalletKit"]),
    ],
    dependencies: [
        .package(url: "https://github.com/krzyzanowskim/CryptoSwift.git", .upToNextMajor(from: "1.8.4")),
        .package(name: "secp256k1", url: "https://github.com/21-DOT-DEV/swift-secp256k1", .exact("0.19.0")),
    ],
    targets: [
        // Targets are the basic building blocks of a package, defining a module or a test suite.
        // Targets can depend on other targets in this package and products from dependencies.
        .target(
            name: "HDWalletKit",
            dependencies: ["CryptoSwift", "secp256k1"]
        ),
        .testTarget(
            name: "HDWalletKitTests",
            dependencies: ["HDWalletKit"]
        ),
    ]
)
