// swift-tools-version:5.5

import PackageDescription

let package = Package(
  name: "SwiftProtobufGen",
  platforms: [.macOS(.v11)],
  products: [.executable(name: "SwiftProtobufGen", targets: ["SwiftProtobufGen"])],
  dependencies: [
    .package(url: "https://github.com/yanagiba/swift-ast.git", from: "0.19.9"),
    .package(url: "https://github.com/apple/swift-argument-parser", from: "1.0.1"),
  ],
  targets: [
    .executableTarget(
      name: "SwiftProtobufGen",
      dependencies: [
        .product(name: "SwiftAST+Tooling", package: "swift-ast"),
        .product(name: "ArgumentParser", package: "swift-argument-parser")
      ]),
    .testTarget(
      name: "SwiftProtobufGenTests",
      dependencies: ["SwiftProtobufGen"]),
  ]
)
