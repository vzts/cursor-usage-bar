// swift-tools-version: 5.9
import PackageDescription

let package = Package(
  name: "CursorUsageBar",
  platforms: [.macOS(.v14)],
  targets: [
    .executableTarget(
      name: "CursorUsageBar",
      path: "Sources/CursorUsageBar",
      linkerSettings: [
        .linkedLibrary("sqlite3"),
      ]
    )
  ]
)
