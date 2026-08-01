// swift-tools-version: 5.9

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
  swiftLanguageVersions: [.v5]
)
