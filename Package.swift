// swift-tools-version:5.6
// The swift-tools-version declares the minimum version of Swift required to build this package.
import PackageDescription

let package = Package(
    name: "ghl-bridge",
    platforms: [
        .macOS("13")
    ],
    products: [
        .executable(name: "ghl-bridge", targets: ["ghl-bridge"]),
    ],
    dependencies: [
        .package(url: "https://github.com/apple/swift-argument-parser", .upToNextMajor(from: "1.2.2")),
        .package(url: "https://github.com/mxcl/Chalk", .upToNextMajor(from: "0.5.0")),
    ],
    targets: [
        .executableTarget(
            name: "ghl-bridge",
            dependencies: [
                .product(name: "ArgumentParser", package: "swift-argument-parser"),
                .product(name: "Chalk", package: "Chalk"),
                ],
            linkerSettings: [
                .unsafeFlags([
                    "-Xlinker", "-sectcreate",
                    "-Xlinker", "__TEXT",
                    "-Xlinker", "__info_plist",
                    "-Xlinker", "./Supporting/Info.plist"
                ])
            ]
        ),
        .testTarget(
            name: "ghl-bridgeTests",
            dependencies: ["ghl-bridge"]),
    ]
)
