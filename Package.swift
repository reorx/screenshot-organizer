// swift-tools-version: 6.1
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "screenshot-organizer",
    platforms: [
        .macOS("14.0")
    ],
    products: [
        .executable(name: "ScreenshotOrganizer", targets: ["ScreenshotOrganizer"])
    ],
    dependencies: [
        .package(url: "https://github.com/sindresorhus/KeyboardShortcuts", from: "1.0.0")
    ],
    targets: [
        .executableTarget(
            name: "ScreenshotOrganizer",
            dependencies: ["KeyboardShortcuts"],
            path: "ScreenshotOrganizer"
        )
    ]
)
