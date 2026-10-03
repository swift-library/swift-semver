// swift-tools-version: 6.0
// SPDX-License-Identifier: Apache-2.0 WITH Swift-exception
// Copyright (c) 2026 Xudong Xu and the swift-library project authors

import PackageDescription

let package = Package(
  name: "swift-semver",
  platforms: [.iOS(.v18), .macOS(.v15)],
  products: [.library(name: "SemVer", targets: ["SemVer"])],
  targets: [
    .target(name: "SemVer"),
    .testTarget(name: "SemVerTests", dependencies: ["SemVer"]),
  ]
)
