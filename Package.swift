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
            // 🧬 進化#37: ドキュメント類を明示excludeして"unhandled files"警告をゼロに
            exclude: [
                "tools", "GROWTH", "landing", "Wiki", "zenn",
                "ARTICLE.md", "PH_LAUNCH.md", "PROMOTION.md",
                "README.md", "README_EN.md", "RULES.md", "SECURITY.md", "LICENSE",
            ],
            resources: []
        )
    ]
)
