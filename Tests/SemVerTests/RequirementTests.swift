// SPDX-License-Identifier: Apache-2.0 WITH Swift-exception
// Copyright (c) 2026 Xudong Xu and the swift-library project authors

import Foundation
import SemVer
import Testing

struct RequirementTests {
  @Test(arguments: [
    ("1.2.3", "=1.2.3"),
    ("== 1.2.3+build.42", "=1.2.3+build.42"),
    (">=1.2.0 <2.0.0", ">=1.2.0 && <2.0.0"),
    (">= 1.2.0 && < 2.0.0", ">=1.2.0 && <2.0.0"),
    (">1.2.0&&<=2.0.0||=3.0.0", ">1.2.0 && <=2.0.0 || =3.0.0"),
    ("^0.2.3", "^0.2.3"),
    ("~1.2.3-alpha.1", "~1.2.3-alpha.1"),
    ("*", "*"),
    ("empty", "empty"),
    (" \t empty \n", "empty"),
    ("* && >=1.0.0", ">=1.0.0"),
    ("\t >=1.2.0\n<2.0.0 \r", ">=1.2.0 && <2.0.0"),
  ])
  func parsesAndRoundTrips(_ expression: String, canonical: String) throws {
    let requirement = try VersionRequirement(parsing: expression)
    #expect(requirement.description == canonical)
    #expect(VersionRequirement(expression) == requirement)
    #expect(try VersionRequirement(parsing: requirement.description) == requirement)
  }

  @Test(arguments: [
    ("", VersionRequirement.ParseError.emptyInput),
    (" \t", .emptyInput),
    ("1.2.3-β", .nonASCII),
    ("&& >=1.0.0", .unexpectedToken(index: 0, value: "&&")),
    ("1.0.0 ||", .unexpectedToken(index: 2, value: "<end>")),
    ("1.0.0 &&", .unexpectedToken(index: 2, value: "<end>")),
    ("1.0.0 || || 2.0.0", .unexpectedToken(index: 2, value: "||")),
    ("1.0.0 && && 2.0.0", .unexpectedToken(index: 2, value: "&&")),
    ("1.0.0 | 2.0.0", .unexpectedToken(index: 1, value: "|")),
    ("1.0.0 & 2.0.0", .unexpectedToken(index: 1, value: "&")),
    (">=", .missingVersion(index: 0)),
    (">= || 1.0.0", .missingVersion(index: 0)),
    ("!=1.2.3", .invalidOperator(index: 0, value: "!=")),
    (">=>1.2.3", .invalidOperator(index: 0, value: ">=>")),
    ("^~1.2.3", .invalidOperator(index: 0, value: "^~")),
    ("1.2", .invalidVersion(index: 0, error: .invalidCoreComponentCount(2))),
    (
      ">= 01.2.3",
      .invalidVersion(index: 1, error: .leadingZeroInCoreComponent(index: 0, value: "01"))
    ),
    (
      "~1.2.3-alpha.01",
      .invalidVersion(index: 0, error: .leadingZeroInPrereleaseIdentifier(index: 1, value: "01"))
    ),
  ])
  func reportsMalformedRequirements(_ expression: String, error: VersionRequirement.ParseError) {
    #expect(VersionRequirement(expression) == nil)
    #expect(throws: error) {
      try VersionRequirement(parsing: expression)
    }
  }

  @Test(arguments: [
    (">=1.2.0 && <2.0.0", "1.1.9", false),
    (">=1.2.0 && <2.0.0", "1.2.0", true),
    (">=1.2.0 && <2.0.0", "1.9.9+build", true),
    (">=1.2.0 && <2.0.0", "2.0.0", false),
    (">1.2.0 && <=2.0.0", "1.2.0", false),
    (">1.2.0 && <=2.0.0", "2.0.0", true),
    ("=1.2.3+first", "1.2.3+second", true),
    ("=1.2.3", "1.2.4", false),
    (">=2.0.0 && <1.0.0", "1.5.0", false),
    (">=1.2.0 <2.0.0 || >=3.0.0 <4.0.0", "3.1.0", true),
    (">=1.2.0 <2.0.0 || >=3.0.0 <4.0.0", "2.5.0", false),
    ("*", "0.0.0", true),
  ])
  func comparisonAndAlternativeBounds(_ expression: String, candidate: String, matches: Bool) throws
  {
    let requirement = try VersionRequirement(parsing: expression)
    #expect(requirement.contains(try Version(parsing: candidate)) == matches)
  }

  @Test(arguments: [
    (">=1.2.0 && <2.0.0", "1.3.0-alpha", false, true),
    (">=1.2.0 && <2.0.0", "1.2.0-alpha", false, false),
    (">=1.2.0-alpha && <2.0.0", "1.2.0-alpha", true, true),
    (">=1.2.0-alpha && <2.0.0", "1.3.0-alpha", true, true),
    (">=1.2.0-alpha && <2.0.0", "2.0.0-alpha", false, true),
    (">=1.2.0-alpha && <2.0.0", "2.0.0", false, false),
    (">=1.2.0 && <2.0.0-beta", "1.3.0-alpha", true, true),
    (">=1.2.0 && <2.0.0-beta", "2.0.0-alpha", true, true),
    (">=1.2.0 && <2.0.0-beta", "2.0.0-beta", false, false),
    ("=1.3.0-alpha+first", "1.3.0-alpha+second", true, true),
    ("*", "1.3.0-alpha", false, true),
    (">=1.0.0-alpha <1.3.0 || >=2.0.0 <3.0.0", "2.1.0-alpha", false, true),
    (">=1.0.0-alpha <1.3.0 || >=2.0.0 <3.0.0", "1.2.0-alpha", true, true),
  ])
  func swiftPMPrereleaseRules(
    _ expression: String, candidate: String, matches: Bool, includingPrereleases: Bool
  ) throws {
    let requirement = try VersionRequirement(parsing: expression)
    let version = try Version(parsing: candidate)
    #expect(requirement.contains(version) == matches)
    #expect(requirement.contains(version, includingPrereleases: true) == includingPrereleases)
  }

  @Test(arguments: [
    ("^1.2.3", "1.9.9", true),
    ("^1.2.3", "1.2.2", false),
    ("^1.2.3", "2.0.0", false),
    ("^1.2.3", "2.0.0-alpha", false),
    ("^0.2.3", "0.2.9", true),
    ("^0.2.3", "0.3.0-alpha", false),
    ("^0.0.3", "0.0.3", true),
    ("^0.0.3", "0.0.4", false),
    ("^0.0.0", "0.0.0", true),
    ("^0.0.0", "0.0.1", false),
    ("~1.2.3", "1.2.9", true),
    ("~1.2.3", "1.3.0-alpha", false),
    ("^0.2.3-alpha", "0.2.4-beta", true),
    ("~1.2.3-alpha", "1.2.4-beta", true),
  ])
  func compatibilityBounds(_ expression: String, candidate: String, matches: Bool) throws {
    let requirement = try VersionRequirement(parsing: expression)
    let version = try Version(parsing: candidate)
    #expect(requirement.contains(version) == matches)
    #expect(requirement.contains(version, includingPrereleases: true) == matches)
  }

  @Test func compatibilityBoundsDoNotOverflow() {
    let maximum = Version(Int.max, Int.max, Int.max)
    let major = VersionRequirement(all: [.compatibleWith(Version(Int.max, 0, 0))])
    #expect(major.contains(maximum))
    let minor = VersionRequirement(all: [.upToNextMinor(Version(Int.max, Int.max, 0))])
    #expect(minor.contains(maximum))
    #expect(!minor.contains(Version(Int.max, Int.max - 1, Int.max)))
    let zeroMajor = VersionRequirement(all: [.compatibleWith(Version(0, Int.max, 0))])
    #expect(zeroMajor.contains(Version(0, Int.max, Int.max)))
  }

  @Test func constructsRequirementsFromSwiftRanges() throws {
    let lower = try Version(parsing: "1.2.0-alpha")
    let upper = Version(2, 0, 0)
    let halfOpen = VersionRequirement(lower..<upper)
    let closed = VersionRequirement(lower...upper)
    let beforeUpper = try Version(parsing: "2.0.0-alpha")
    #expect(!halfOpen.contains(upper))
    #expect(closed.contains(upper))
    #expect(!halfOpen.contains(beforeUpper))
    #expect(closed.contains(beforeUpper))
    #expect(!VersionRequirement(upper..<upper).contains(upper))
    #expect(VersionRequirement(upper...upper).contains(upper))
  }

  @Test func typedAlternativesAndWildcard() throws {
    let requirement = VersionRequirement(any: [
      [.atLeast(Version(1, 0, 0)), .lessThan(Version(2, 0, 0))],
      [.exact(Version(3, 0, 0))],
    ])
    #expect(requirement.contains(Version(1, 2, 3)))
    #expect(requirement.contains(Version(3, 0, 0)))
    #expect(!requirement.contains(Version(2, 1, 0)))
    #expect(try VersionRequirement(parsing: requirement.description) == requirement)
    #expect(VersionRequirement.any.contains(Version(0, 0, 0)))
    #expect(!VersionRequirement.any.contains(try Version(parsing: "1.0.0-alpha")))
  }

  @Test func emptyRequirementRoundTripsAndMatchesNothing() throws {
    let requirement = VersionRequirement(any: [])
    #expect(requirement == .empty)
    #expect(requirement.description == "empty")
    #expect(try VersionRequirement(parsing: requirement.description) == requirement)
    #expect(
      try JSONDecoder().decode(VersionRequirement.self, from: JSONEncoder().encode(requirement))
        == requirement)
    for version in [Version(0, 0, 0), Version(1, 2, 3), try Version(parsing: "1.0.0-alpha")] {
      #expect(!requirement.contains(version))
      #expect(!requirement.contains(version, includingPrereleases: true))
    }
    #expect(VersionRequirement("empty || *") == nil)
    #expect(VersionRequirement("* && empty") == nil)
  }

  @Test func codingPreservesExpressionsAndParsingErrors() throws {
    let requirement = try VersionRequirement(parsing: ">=1.2.3-alpha.1+build && <2.0.0")
    let encoded = try JSONEncoder().encode(requirement)
    let decoded = try JSONDecoder().decode(VersionRequirement.self, from: encoded)
    #expect(decoded == requirement)
    #expect(decoded.description == requirement.description)

    struct Payload: Decodable {
      let requirement: VersionRequirement
    }
    do {
      _ = try JSONDecoder().decode(Payload.self, from: Data(#"{"requirement":">= 01.2.3"}"#.utf8))
      Issue.record("Decoding an invalid requirement should fail.")
    } catch DecodingError.dataCorrupted(let context) {
      #expect(context.codingPath.map(\.stringValue) == ["requirement"])
      #expect(
        context.underlyingError as? VersionRequirement.ParseError
          == .invalidVersion(index: 1, error: .leadingZeroInCoreComponent(index: 0, value: "01")))
    }
    #expect(throws: DecodingError.self) {
      try JSONDecoder().decode(VersionRequirement.self, from: Data("123".utf8))
    }
  }

  @Test func equalityAndHashingIgnoreBoundMetadata() throws {
    let first = try VersionRequirement(parsing: ">=1.2.3+first && <2.0.0")
    let second = try VersionRequirement(parsing: ">=1.2.3+second && <2.0.0")
    #expect(first == second)
    #expect(Set([first, second]).count == 1)
    #expect(first.description != second.description)
  }

  @Test func requirementsCrossTaskBoundaries() async throws {
    let requirement = try VersionRequirement(parsing: ">=1.2.0 && <2.0.0")
    let returned = await Task.detached { requirement }.value
    #expect(returned == requirement)
    #expect(returned.contains(Version(1, 3, 0)))
  }
}
