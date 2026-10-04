// SPDX-License-Identifier: Apache-2.0 WITH Swift-exception
// Copyright (c) 2026 Xudong Xu and the swift-library project authors

import SemVer
import Testing

struct IncrementingTests {
  @Test(arguments: [
    ("1.2.3", Version.Component.major, "2.0.0"),
    ("1.2.3", .minor, "1.3.0"),
    ("1.2.3", .patch, "1.2.4"),
    ("0.0.0", .major, "1.0.0"),
    ("0.0.0", .minor, "0.1.0"),
    ("0.0.0", .patch, "0.0.1"),
    ("1.2.3-alpha.1+build.42", .major, "2.0.0"),
    ("1.2.3-alpha.1+build.42", .minor, "1.3.0"),
    ("1.2.3-alpha.1+build.42", .patch, "1.2.4"),
  ])
  func incrementsCore(_ text: String, component: Version.Component, expected: String) throws {
    let original = try Version(parsing: text)
    let incremented = try original.incrementing(component)
    #expect(incremented.description == expected)
    #expect(original.description == text)
    #expect(incremented > original)
  }

  @Test(arguments: [Version.Component.major, .minor, .patch])
  func reportsOverflow(_ component: Version.Component) {
    let version = Version(Int.max, Int.max, Int.max)
    #expect(throws: Version.IncrementError.overflow(component)) {
      try version.incrementing(component)
    }
  }

  @Test func resetsLowerComponentsAtTheirLimits() throws {
    #expect(try Version(1, Int.max, Int.max).incrementing(.major) == Version(2, 0, 0))
    #expect(try Version(1, 2, Int.max).incrementing(.minor) == Version(1, 3, 0))
  }

  @Test(arguments: [
    ("1.2.3-alpha.1", "1.2.3-alpha.2"),
    ("1.2.3-alpha", "1.2.3-alpha.0"),
    ("1.2.3-alpha.beta", "1.2.3-alpha.beta.0"),
    ("1.2.3-0", "1.2.3-1"),
    ("1.2.3-alpha.9", "1.2.3-alpha.10"),
    ("1.2.3-alpha.1.beta.9", "1.2.3-alpha.1.beta.10"),
    ("1.2.3-alpha.9.beta", "1.2.3-alpha.10.beta"),
    ("1.2.3-alpha-1", "1.2.3-alpha-1.0"),
    ("1.2.3-alpha.1+build.42", "1.2.3-alpha.2"),
    ("1.2.3", "1.2.4-0"),
    ("1.2.3+build.42", "1.2.4-0"),
    ("1.2.3-alpha.999999999999999999999999999999", "1.2.3-alpha.1000000000000000000000000000000"),
  ])
  func incrementsPrereleases(_ text: String, expected: String) throws {
    let original = try Version(parsing: text)
    let incremented = try original.incrementingPrerelease()
    #expect(incremented.description == expected)
    #expect(incremented > original)
    #expect(original.description == text)
    #expect(try Version(parsing: incremented.description) == incremented)
  }

  @Test func prereleaseIncrementAtPatchLimit() throws {
    #expect(throws: Version.IncrementError.overflow(.patch)) {
      try Version(1, 2, Int.max).incrementingPrerelease()
    }
    let preview = Version(1, 2, Int.max, prereleaseIdentifiers: ["alpha", "1"])
    let next = try preview.incrementingPrerelease()
    #expect(next.patch == Int.max)
    #expect(next.prereleaseIdentifiers == ["alpha", "2"])
  }

  @Test(arguments: ["1.2.3-alpha.1+build.42", "1.2.3", "1.2.3+build.42", "0.1.0-rc.1"])
  func promotesToARelease(_ text: String) throws {
    let original = try Version(parsing: text)
    let release = original.releasing()
    #expect(release.major == original.major)
    #expect(release.minor == original.minor)
    #expect(release.patch == original.patch)
    #expect(release.prereleaseIdentifiers.isEmpty)
    #expect(release.buildMetadataIdentifiers.isEmpty)
    #expect(release >= original)
    #expect(release.releasing().description == release.description)
  }
}
