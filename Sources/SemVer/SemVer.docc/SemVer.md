# ``SemVer``

@Metadata {
  @PageImage(purpose: icon, source: "Logo", alt: "swift-semver logo")
  @PageColor(green)
}

Parse, compare, constrain and increment immutable semantic versions.

## Overview

``Version`` represents a SemVer 2.0.0 version as three nonnegative integer
components, optional prerelease identifiers and optional build metadata.
The library uses the Swift standard library and has zero external dependencies.
``VersionRequirement`` matches version ranges and comparison alternatives.
Version increment methods return a new version, checking core overflow and
supporting numeric prerelease identifiers of arbitrary length.

## Parsing versions

The failable initializer returns nil when the input is invalid. The throwing
initializer reports a ``Version/ParseError`` with the invalid component or identifier:

```swift
import SemVer

let release = Version("1.2.3")
let preview = try Version(parsing: "1.2.3-alpha.1+build.42")
```

Both initializers enforce the same syntax. Core components fit in a nonnegative
Swift Int. Numeric prerelease identifiers can contain arbitrarily many digits.
Identifiers contain ASCII letters, digits or hyphens and are nonempty. Core
components and numeric prerelease identifiers use canonical digits with no
leading zeroes except for zero itself.

```swift
do {
  _ = try Version(parsing: "1.2.3-alpha.01")
} catch {
  switch error {
  case .leadingZeroInPrereleaseIdentifier(let index, let value):
    print(index, value) // 1 01
  default:
    print(error)
  }
}
```

Error indexes are zero-based within the core, prerelease or build metadata list.
For the core, indexes zero, one and two correspond to major, minor and patch.

## Comparing versions

Ordering follows SemVer 2.0.0 precedence. Core components compare numerically.
Prerelease versions sort before the corresponding release. Numeric prerelease
identifiers compare numerically, and nonnumeric identifiers use ASCII ordering.
Numeric identifiers sort before nonnumeric identifiers.

```swift
let alpha = try Version(parsing: "1.2.3-alpha")
let beta = try Version(parsing: "1.2.3-beta.1")
let release = Version(1, 2, 3)

print(alpha < beta) // true
print(beta < release) // true
print(alpha.isPrerelease) // true
print(release.isStable) // true
```

The Comparable conformance supports sorting and Swift ranges. Swift's ordinary
Range.contains uses version ordering. Wrap a range in ``VersionRequirement`` to
apply prerelease eligibility as well. A stable version has a positive major
component and no prerelease identifiers.

## Preserving build metadata

Equality, ordering and hashing use version precedence and ignore build metadata.
Descriptions and Codable values preserve the complete version:

```swift
let first = try Version(parsing: "1.2.3+first")
let second = try Version(parsing: "1.2.3+second")

print(first == second) // true
print(first.description) // 1.2.3+first
print(Set([first, second]).count) // 1
```

Codable encodes a single version string. Decoding validates that string using the
strict parser. A malformed string produces a data-corrupted decoding error whose
underlying error is the structured parsing error.

## Topics

### Versions

- ``Version``

### Range requirements

- <doc:Ranges>
- ``VersionRequirement``
- ``VersionRequirement/Comparator``

### Incrementing versions

- <doc:Incrementing>
- ``Version/Component``
- ``Version/IncrementError``

### Parsing errors

- ``Version/ParseError``
- ``VersionRequirement/ParseError``
