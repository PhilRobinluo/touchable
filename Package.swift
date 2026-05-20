// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "TouchAble",
    platforms: [
        .macOS(.v14)
    ],
    products: [
        .executable(name: "TouchAble", targets: ["TouchAble"]),
        .library(name: "TouchAbleCore", targets: ["TouchAbleCore"])
    ],
    targets: [
        .target(name: "TouchAbleCore"),
        .executableTarget(
            name: "TouchAble",
            dependencies: ["TouchAbleCore"]
        ),
        .testTarget(
            name: "TouchAbleTests",
            dependencies: ["TouchAbleCore"]
        )
    ]
)
