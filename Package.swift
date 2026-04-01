// swift-tools-version: 6.2

import PackageDescription

let package = Package(
    name: "oxford",
    platforms: [
        .macOS(.v10_15)
    ],
    products: [
        .executable(
            name: "oxford",
            targets: ["Oxford"]
        ),
    ],
    dependencies: [
        .package(url: "https://github.com/apple/swift-argument-parser.git", from: "1.7.0"),
        .package(url: "https://github.com/onevcat/Rainbow.git", from: "4.0.0"),
    ],
    targets: [
        .target(
            name: "OxfordKit",
            dependencies: [
                "Rainbow",
            ]
        ),
        .executableTarget(
            name: "Oxford",
            dependencies: [
                "OxfordKit",
                .product(name: "ArgumentParser", package: "swift-argument-parser"),
            ]
        ),
        .testTarget(
            name: "OxfordTests",
            dependencies: ["OxfordKit"]
        ),
    ]
)
