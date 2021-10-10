// swift-tools-version:5.5

import PackageDescription

let package = Package(
  name: "SwiftProtobufGen",
  platforms: [.macOS(.v11)],
  products: [.executable(name: "SwiftProtobufGen", targets: ["SwiftProtobufGen"])],
  dependencies: [
//    .package(name: "SwiftSyntax", url: "https://github.com/apple/swift-syntax.git", .exact("0.50500.0")),
    .package(url: "https://github.com/yanagiba/swift-ast.git", from: "0.19.9"),
  ],
  targets: [
    .executableTarget(
      name: "SwiftProtobufGen",
      dependencies: [.product(name: "SwiftAST+Tooling", package: "swift-ast")]),
    .testTarget(
      name: "SwiftProtobufGenTests",
      dependencies: ["SwiftProtobufGen"]),
  ]
)
