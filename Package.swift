// swift-tools-version: 5.10
// QuickFinder — app barre de menu macOS
import PackageDescription

let package = Package(
    name: "QuickFinder",
    platforms: [.macOS(.v13)],
    dependencies: [
        .package(url: "https://github.com/sindresorhus/KeyboardShortcuts", from: "2.0.0"),
    ],
    targets: [
        .executableTarget(
            name: "QuickFinder",
            dependencies: [
                .product(name: "KeyboardShortcuts", package: "KeyboardShortcuts"),
            ],
            path: "Sources/QuickFinder"
        ),
    ]
)
