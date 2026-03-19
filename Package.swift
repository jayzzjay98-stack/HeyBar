// swift-tools-version: 6.2

import PackageDescription

let package = Package(
    name: "HeyBar",
    platforms: [
        .macOS(.v13)
    ],
    products: [
        .executable(
            name: "HeyBar",
            targets: ["HeyBar"]
        )
    ],
    targets: [
        .target(
            name: "NightShiftBridge",
            path: "Sources/NightShiftBridge",
            publicHeadersPath: "include"
        ),
        .executableTarget(
            name: "HeyBar",
            dependencies: ["NightShiftBridge"]
        ),
        .testTarget(
            name: "HeyBarTests",
            dependencies: ["HeyBar"]
        ),
    ]
)
