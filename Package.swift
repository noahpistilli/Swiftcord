// swift-tools-version:5.5
import PackageDescription

let package = Package(
  name: "Swiftcord",
  platforms: [.macOS("12") ],
  products: [
    .library(name: "Swiftcord", targets: ["Swiftcord"])
  ],
  dependencies: [
    // WebSockets for Linux and macOS
    .package(url: "https://github.com/vapor/websocket-kit", .branch("main")),
    
    // Logging for Swift
    .package(url: "https://github.com/apple/swift-log.git", .branch("main")),
    
    // Library that contains common mimetypes
    .package(url: "https://github.com/SketchMaster2001/MimeType.git", .branch("master")),
    
    // Voice packet encryption
    .package(url: "https://github.com/nuclearace/Sodium", .branch("master")),
    
    // Opus bindings for SPM
    .package(url: "https://github.com/SketchMaster2001/Opus", .branch("master")),
    
    // FFmpeg bindings for SPM
    .package(url: "https://github.com/sunlubo/SwiftFFmpeg", branch: "master")
  ],
  targets: [
    .target(
      name: "Swiftcord",
      dependencies: [
        .product(name: "WebSocketKit", package: "websocket-kit"),
        .product(name: "Logging", package: "swift-log"),
        "MimeType",
        "Sodium",
        "Opus",
        "SwiftFFmpeg"
      ]
    ),
    .testTarget(
        name: "SwiftcordTests",
        dependencies: [.target(name: "Swiftcord")]
    )
  ]
)
