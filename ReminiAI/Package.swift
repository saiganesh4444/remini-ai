// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "ReminiAI",
    platforms: [
        .iOS(.v16)
    ],
    products: [
        .library(
            name: "ReminiAI",
            targets: ["ReminiAI"]
        ),
    ],
    dependencies: [],
    targets: [
        .target(
            name: "ReminiAI",
            dependencies: [],
            path: "ReminiAI"
        )
    ]
)
