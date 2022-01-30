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
    // Coloured output for logging
    .package(url: "https://github.com/onevcat/Rainbow", .upToNextMajor(from: "4.0.0"))
  ],
  targets: [
    .target(
      name: "Swiftcord",
      dependencies: [.product(name: "WebSocketKit", package: "websocket-kit"), "Rainbow"]
    ),
    .testTarget(
        name: "SwiftcordTests",
        dependencies: [.target(name: "Swiftcord")]
    )
  ]
)
