// swift-tools-version:5.3
import PackageDescription

let package = Package(
  name: "Sword",
  platforms: [.macOS(.v10_15),],
  products: [
    .library(name: "Sword", targets: ["Sword"])
  ],
  dependencies: [
    .package(url: "https://github.com/vapor/websocket-kit", .branch("main"))
  ],
  targets: [
    .target(
      name: "Sword",
      dependencies: [.product(name: "WebSocketKit", package: "websocket-kit")]
    )
  ]
)
