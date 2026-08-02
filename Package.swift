// swift-tools-version: 6.0

import PackageDescription

let package = Package(
  name: "OpenSourceLicenses",
  platforms: [
    .macOS(.v14)
  ],
  products: [
    .library(
      name: "OpenSourceLicenses",
      targets: ["OpenSourceLicenses"]
    )
  ],
  targets: [
    .target(
      name: "OpenSourceLicenses"
    ),
    .testTarget(
      name: "OpenSourceLicensesTests",
      dependencies: ["OpenSourceLicenses"]
    )
  ],
  swiftLanguageModes: [.v5]
)
