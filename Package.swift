// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "Conscio",
    platforms: [
        .macOS(.v13)
    ],
    products: [
        .executable(
            name: "Conscio",
            targets: ["Conscio"]
        )
    ],
    targets: [
        .executableTarget(
            name: "Conscio",
            path: "Conscio",
            resources: []
        )
    ]
)
