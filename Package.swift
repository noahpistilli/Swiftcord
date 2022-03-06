// swift-tools-version:5.5
import PackageDescription

let package = Package(
  name: "Swiftcord",
  platforms: [.macOS("12"),],
  products: [
    .library(name: "Swiftcord", targets: ["Swiftcord"])
  ],
  dependencies: [
    // WebSockets for Linux and macOS
    .package(url: "https://github.com/vapor/websocket-kit", .branch("main")),
    // Logging for Swift
    .package(url: "https://github.com/apple/swift-log.git", from: "1.4.2"),
  ],
  targets: [
    .target(
      name: "Swiftcord",
      dependencies: [.product(name: "WebSocketKit", package: "websocket-kit"), .product(name: "Logging", package: "swift-log")]
    ),
    .testTarget(
        name: "SwiftcordTests",
        dependencies: [.target(name: "Swiftcord")]
    )
  ]
)
