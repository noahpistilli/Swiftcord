// swift-tools-version:5.3
import PackageDescription

let package = Package(
  name: "Sword",
  platforms: [.macOS(.v10_15),],
  products: [
    .library(name: "Sword", targets: ["Sword"])
  ],
  dependencies: [
    // WebSockets for Linux and macOS
    .package(url: "https://github.com/vapor/websocket-kit", .branch("main")),
    // Coloured output for logging
    .package(url: "https://github.com/onevcat/Rainbow", .upToNextMajor(from: "4.0.0"))
  ],
  targets: [
    .target(
      name: "Sword",
      dependencies: [.product(name: "WebSocketKit", package: "websocket-kit"), "Rainbow"]
    )
  ]
)
