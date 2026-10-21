// swift-tools-version: 6.0
import PackageDescription

extension Target.Dependency {
    static var peripheryKit: Self {
        .product(name: "PeripheryKit_static", package: "PeripheryKit", condition: .when(platforms: [.linux]))
    }
}

let package = Package(
    name: "RPiKit",
    platforms: [
        .macOS(.v14)
    ],
    products: [
        .library(name: "RPiKit", targets: ["RPiKit"]),
        .library(name: "RPiHAL", targets: ["RPiHAL"]),
        .library(name: "RPiLinux", targets: ["RPiLinux"]),
        .library(name: "RPiGraphics", targets: ["RPiGraphics"]),
        .library(name: "RPiDisplays", targets: ["RPiDisplays"]),
        .library(name: "RPiPeripherals", targets: ["RPiPeripherals"]),
    ],
    dependencies: [
        .package(url: "https://github.com/CmST0us/PeripheryKit.git", branch: "main"),
    ],
    targets: [
        .target(
            name: "RPiHAL"
        ),
        .target(
            name: "RPiLinux",
            dependencies: [
                "RPiHAL",
                .peripheryKit,
            ]
        ),
        .target(
            name: "RPiGraphics"
        ),
        .target(
            name: "RPiDisplays",
            dependencies: [
                "RPiHAL",
                "RPiLinux",
                "RPiGraphics",
            ]
        ),
        .target(
            name: "RPiPeripherals",
            dependencies: [
                "RPiHAL",
                "RPiLinux",
            ]
        ),
        .target(
            name: "RPiKit",
            dependencies: [
                "RPiHAL",
                "RPiGraphics",
                "RPiDisplays",
                "RPiPeripherals",
            ]
        ),
        .testTarget(
            name: "RPiHALTests",
            dependencies: ["RPiHAL"]
        ),
        .testTarget(
            name: "RPiGraphicsTests",
            dependencies: ["RPiGraphics"]
        ),
        .testTarget(
            name: "RPiDisplaysTests",
            dependencies: ["RPiDisplays", "RPiHAL", "RPiGraphics"]
        ),
        .testTarget(
            name: "RPiPeripheralsTests",
            dependencies: ["RPiPeripherals", "RPiHAL"]
        ),
    ]
)
