// swift-tools-version: 6.1
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "XCCache",
    platforms: [
        .iOS(.v13),
        .macOS(.v10_15),
    ],
    products: [
        .library(
            name: "XCCache",
            targets: ["XCCache"]),
    ],
    dependencies: [
        .package(url: "https://github.com/hyperoslo/Cache.git", from: "7.4.0"),
        .package(url: "https://github.com/min554357332/CacheDataPreprocessor.git", from: "0.0.1"),
    ],
    targets: [
        .target(
            name: "XCCache",
            dependencies: ["Cache","CacheDataPreprocessor"]
        ),
    ]
)
