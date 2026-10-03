// SPDX-License-Identifier: Apache-2.0 WITH Swift-exception
// Copyright (c) 2026 Xudong Xu and the swift-library project authors

import Foundation
import SemVer
import Testing

@Suite("Semantic versions")
struct VersionTests {
  @Test(arguments: [
    "0.0.0", "1.2.3", "10.20.30", "1.0.0-alpha", "1.0.0-alpha.1",
    "1.0.0-0.3.7", "1.0.0-x.7.z.92", "1.0.0-x-y-z.--", "1.0.0--",
    "1.0.0-01a", "1.0.0+001", "1.0.0+20130313144700", "1.0.0+-",
    "1.0.0-beta+exp.sha.5114f85", "1.0.0+21AF26D3----117B344092BD",
    "1.0.0-99999999999999999999999999999999999999999999",
  ])
  func validStringsRoundTrip(_ text: String) throws {
    let version = try #require(Version(text))
    #expect(version.description == text)
    #expect(Version(version.description) == version)
  }

  @Test(arguments: [
    "", "1", "1.2", "1.2.3.4", ".1.2", "1..2", "1.2.", "01.2.3",
    "1.02.3", "1.2.03", "00.0.0", "+1.2.3", "-1.2.3", "1.-2.3",
    "v1.2.3", " 1.2.3", "1.2.3 ", "1.2.3\n", "１.2.3", "1.2.3-",
    "1.2.3+", "1.2.3-alpha.", "1.2.3-.alpha", "1.2.3-alpha..1",
    "1.2.3-01", "1.2.3-alpha.01", "1.2.3+build.", "1.2.3+.build",
    "1.2.3+build..1", "1.2.3+build+other", "1.2.3-a_b", "1.2.3+a_b",
    "1.2.3-β", "1.2.3+构建", "1.2.3-alpha+", "1.2.3-+build",
    "99999999999999999999999999999999999999999.0.0",
  ])
  func invalidStringsReturnNil(_ text: String) {
    #expect(Version(text) == nil)
  }

  @Test func componentsAndIntBoundary() throws {
    let version = Version(
      1, 2, 3, prereleaseIdentifiers: ["rc", "1"], buildMetadataIdentifiers: ["001", "sha"])
    #expect(version.major == 1)
    #expect(version.minor == 2)
    #expect(version.patch == 3)
    #expect(version.prereleaseIdentifiers == ["rc", "1"])
    #expect(version.buildMetadataIdentifiers == ["001", "sha"])
    #expect(version.description == "1.2.3-rc.1+001.sha")
    #expect(Version("\(Int.max).0.0") == Version(Int.max, 0, 0))
    #expect(Version("\(UInt(Int.max) + 1).0.0") == nil)
    #expect(Version("1.2.3-rc.1+001.sha")?.description == version.description)
    #expect(Version("01.2.3") == nil)
  }

  @Test func specificationPrecedence() throws {
    let texts = [
      "0.9.9", "1.0.0-alpha", "1.0.0-alpha.1", "1.0.0-alpha.beta", "1.0.0-beta",
      "1.0.0-beta.2", "1.0.0-beta.11", "1.0.0-rc.1", "1.0.0", "1.0.1", "1.1.0", "2.0.0",
    ]
    let versions = try texts.map { try #require(Version($0)) }
    for i in versions.indices {
      #expect(!(versions[i] < versions[i]))
      for j in versions.indices where i < j {
        #expect(versions[i] < versions[j])
        #expect(!(versions[j] < versions[i]))
        #expect(versions[i] != versions[j])
      }
    }
    #expect(versions.reversed().sorted() == versions)
  }

  @Test func arbitrarilyLargeNumericPrereleaseIdentifiers() throws {
    let texts = [
      "1.0.0-9", "1.0.0-10", "1.0.0-99999999999999999999",
      "1.0.0-100000000000000000000", "1.0.0-200000000000000000000",
      "1.0.0-alpha", "1.0.0",
    ]
    let versions = try texts.map { try #require(Version($0)) }
    for (left, right) in zip(versions, versions.dropFirst()) {
      #expect(left < right)
      #expect(!(right < left))
    }
  }

  @Test func metadataPreservesRepresentationAndSharesPrecedence() throws {
    let plain = try #require(Version("1.2.3-rc.1"))
    let left = try #require(Version("1.2.3-rc.1+first"))
    let right = try #require(Version("1.2.3-rc.1+second"))
    #expect(plain == left)
    #expect(left == right)
    #expect(!(left < right))
    #expect(!(right < left))
    #expect(Set([plain, left, right]).count == 1)
    #expect(left.description != right.description)
  }

  @Test func codingUsesACompleteString() throws {
    let version = try #require(Version("1.2.3-rc.1+001.sha"))
    let encoded = try JSONEncoder().encode(version)
    #expect(String(decoding: encoded, as: UTF8.self) == "\"1.2.3-rc.1+001.sha\"")
    let decoded = try JSONDecoder().decode(Version.self, from: encoded)
    #expect(decoded.description == version.description)
    #expect(decoded.buildMetadataIdentifiers == ["001", "sha"])
    #expect(throws: DecodingError.self) {
      try JSONDecoder().decode(Version.self, from: Data("\"1.2\"".utf8))
    }
    #expect(throws: DecodingError.self) {
      try JSONDecoder().decode(Version.self, from: Data("123".utf8))
    }
  }

  @Test func versionsCrossTaskBoundaries() async throws {
    let version = try #require(Version("1.2.3+build"))
    let returned = await Task.detached { version }.value
    #expect(returned.description == version.description)
  }
}
