// SPDX-License-Identifier: Apache-2.0 WITH Swift-exception
// Copyright (c) 2018-2021 Apple Inc. and the Swift project authors
// Copyright (c) 2026 Xudong Xu and the swift-library project authors
// Adapted from SwiftPM's PackageDescription.Version. See NOTICE for provenance and modifications.

/// An immutable semantic version with SemVer 2.0.0 precedence.
///
/// Major, minor and patch components are nonnegative values representable by `Int`.
/// Equality, ordering and hashing ignore build metadata. The original metadata
/// remains available in ``buildMetadataIdentifiers`` and ``description``.
public struct Version: Sendable {
  /// The major version component.
  public let major: Int

  /// The minor version component.
  public let minor: Int

  /// The patch version component.
  public let patch: Int

  /// Dot-separated prerelease identifiers; an empty array denotes a stable version.
  public let prereleaseIdentifiers: [String]

  /// Dot-separated build metadata, preserved independently of version precedence.
  public let buildMetadataIdentifiers: [String]

  /// Creates a version from validated components.
  ///
  /// - Precondition: Core components are nonnegative. Every identifier is nonempty
  ///   and contains only ASCII letters, digits or hyphens. Numeric prerelease
  ///   identifiers have no leading zeroes unless the identifier is `"0"`.
  public init(
    _ major: Int,
    _ minor: Int,
    _ patch: Int,
    prereleaseIdentifiers: [String] = [],
    buildMetadataIdentifiers: [String] = []
  ) {
    precondition(major >= 0 && minor >= 0 && patch >= 0, "Negative version components are invalid.")
    precondition(
      prereleaseIdentifiers.allSatisfy(Self.isValidPrereleaseIdentifier),
      "Invalid prerelease identifier.")
    precondition(
      buildMetadataIdentifiers.allSatisfy(Self.isValidIdentifier),
      "Invalid build metadata identifier.")
    self.major = major
    self.minor = minor
    self.patch = patch
    self.prereleaseIdentifiers = prereleaseIdentifiers
    self.buildMetadataIdentifiers = buildMetadataIdentifiers
  }

  private static func isNumeric<S: StringProtocol>(_ identifier: S) -> Bool {
    !identifier.isEmpty && identifier.utf8.allSatisfy { (48...57).contains($0) }
  }

  private static func isValidIdentifier(_ identifier: String) -> Bool {
    !identifier.isEmpty
      && identifier.utf8.allSatisfy {
        $0 == 45 || (48...57).contains($0) || (65...90).contains($0) || (97...122).contains($0)
      }
  }

  private static func isValidPrereleaseIdentifier(_ identifier: String) -> Bool {
    isValidIdentifier(identifier)
      && (!isNumeric(identifier) || identifier == "0" || identifier.first != "0")
  }
}

extension Version: LosslessStringConvertible {
  /// Parses `MAJOR.MINOR.PATCH[-PRERELEASE][+BUILD]`.
  ///
  /// Returns `nil` for invalid SemVer syntax or core components outside `Int`'s
  /// range. Prefixes, surrounding whitespace and missing core components are
  /// invalid. Numeric prerelease identifiers may contain arbitrarily many digits.
  public init?(_ versionString: String) {
    guard versionString.allSatisfy(\.isASCII) else { return nil }

    let metadataDelimiter = versionString.firstIndex(of: "+")
    let prereleaseDelimiter = versionString[..<(metadataDelimiter ?? versionString.endIndex)]
      .firstIndex(of: "-")
    let core = versionString[
      ..<(prereleaseDelimiter ?? metadataDelimiter ?? versionString.endIndex)
    ]
    .split(separator: ".", omittingEmptySubsequences: false)

    func component(_ text: Substring) -> Int? {
      guard Self.isNumeric(text), text == "0" || text.first != "0" else { return nil }
      return Int(text)
    }

    guard core.count == 3,
      let major = component(core[0]),
      let minor = component(core[1]),
      let patch = component(core[2])
    else { return nil }

    let prereleaseIdentifiers: [String]
    if let prereleaseDelimiter {
      let start = versionString.index(after: prereleaseDelimiter)
      prereleaseIdentifiers = versionString[start..<(metadataDelimiter ?? versionString.endIndex)]
        .split(separator: ".", omittingEmptySubsequences: false).map(String.init)
    } else {
      prereleaseIdentifiers = []
    }

    let buildMetadataIdentifiers: [String]
    if let metadataDelimiter {
      let start = versionString.index(after: metadataDelimiter)
      buildMetadataIdentifiers = versionString[start...]
        .split(separator: ".", omittingEmptySubsequences: false).map(String.init)
    } else {
      buildMetadataIdentifiers = []
    }

    guard prereleaseIdentifiers.allSatisfy(Self.isValidPrereleaseIdentifier),
      buildMetadataIdentifiers.allSatisfy(Self.isValidIdentifier)
    else { return nil }

    self.major = major
    self.minor = minor
    self.patch = patch
    self.prereleaseIdentifiers = prereleaseIdentifiers
    self.buildMetadataIdentifiers = buildMetadataIdentifiers
  }

  /// The canonical version string, including prerelease and build metadata.
  public var description: String {
    var result = "\(major).\(minor).\(patch)"
    if !prereleaseIdentifiers.isEmpty {
      result += "-" + prereleaseIdentifiers.joined(separator: ".")
    }
    if !buildMetadataIdentifiers.isEmpty {
      result += "+" + buildMetadataIdentifiers.joined(separator: ".")
    }
    return result
  }
}

extension Version: Comparable {
  /// Compares version precedence, ignoring build metadata.
  public static func == (lhs: Version, rhs: Version) -> Bool {
    lhs.major == rhs.major && lhs.minor == rhs.minor && lhs.patch == rhs.patch
      && lhs.prereleaseIdentifiers == rhs.prereleaseIdentifiers
  }

  /// Orders versions according to SemVer 2.0.0, ignoring build metadata.
  public static func < (lhs: Version, rhs: Version) -> Bool {
    let lhsCore = [lhs.major, lhs.minor, lhs.patch]
    let rhsCore = [rhs.major, rhs.minor, rhs.patch]
    if lhsCore != rhsCore {
      return lhsCore.lexicographicallyPrecedes(rhsCore)
    }

    guard !lhs.prereleaseIdentifiers.isEmpty else { return false }
    guard !rhs.prereleaseIdentifiers.isEmpty else { return true }

    for (left, right) in zip(lhs.prereleaseIdentifiers, rhs.prereleaseIdentifiers) {
      if left == right { continue }
      let leftIsNumeric = isNumeric(left)
      let rightIsNumeric = isNumeric(right)
      if leftIsNumeric && rightIsNumeric {
        // Canonical ASCII digit strings compare numerically without an integer size limit.
        if left.count != right.count { return left.count < right.count }
        return left < right
      }
      if leftIsNumeric != rightIsNumeric { return leftIsNumeric }
      return left < right
    }
    return lhs.prereleaseIdentifiers.count < rhs.prereleaseIdentifiers.count
  }
}

extension Version: Hashable {
  /// Hashes the components that determine equality.
  public func hash(into hasher: inout Hasher) {
    hasher.combine(major)
    hasher.combine(minor)
    hasher.combine(patch)
    hasher.combine(prereleaseIdentifiers)
  }
}

extension Version: Codable {
  /// Encodes the complete version as a string, preserving build metadata.
  public func encode(to encoder: any Encoder) throws {
    var container = encoder.singleValueContainer()
    try container.encode(description)
  }

  /// Decodes a strict semantic version string.
  public init(from decoder: any Decoder) throws {
    let container = try decoder.singleValueContainer()
    let text = try container.decode(String.self)
    guard let version = Self(text) else {
      throw DecodingError.dataCorruptedError(
        in: container, debugDescription: "Invalid semantic version.")
    }
    self = version
  }
}
