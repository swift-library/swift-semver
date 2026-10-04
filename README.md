<p align="center">
  <img src="Documentation/Assets/Logo.svg" width="160" alt="swift-semver logo">
</p>

<h1 align="center">swift-semver</h1>

<p align="center">
  Parse, compare, constrain, and increment semantic versions in Swift.
</p>

<p align="center">
  <a href="https://github.com/swift-library/swift-semver/actions/workflows/ci.yml"><img src="https://github.com/swift-library/swift-semver/actions/workflows/ci.yml/badge.svg?branch=master" alt="CI"></a>
  <img src="https://img.shields.io/badge/Swift-6.0%2B-F05138" alt="Swift 6.0+">
  <img src="https://img.shields.io/badge/platforms-iOS%2018%2B%20%7C%20macOS%2015%2B%20%7C%20Linux-lightgrey" alt="Platforms: iOS 18+ | macOS 15+ | Linux">
  <a href="LICENSE.txt"><img src="https://img.shields.io/badge/license-Apache--2.0-blue" alt="License: Apache-2.0 WITH Swift-exception"></a>
</p>

[Overview](#overview) · [Install](#install) · [Quick start](#quick-start) ·
[Usage](#usage) · [Requirements](#requirements) · [Documentation](#documentation) ·
[Contributing](#contributing) · [License](#license)

> [!NOTE]
> swift-semver is pre-1.0. Minor releases may include source-breaking
> changes, so depend on it with `.upToNextMinor(from:)`.

## Overview

swift-semver represents semantic versions as immutable Swift values. `Version`
parses SemVer 2.0.0 strings strictly, orders them by SemVer precedence, and
keeps build metadata for display and encoding. `VersionRequirement` checks
versions against ranges and comparison expressions, and the increment methods
return the next major, minor, patch, or prerelease version. The `SemVer`
module uses only the Swift standard library.

- `Version`, a `Sendable`, `Hashable`, `Comparable`, `Codable`, and
  `LosslessStringConvertible` value.
- Failable and throwing parsers, with structured errors that identify the
  invalid component, leading zero, or overflow.
- `VersionRequirement` expressions with comparisons, caret and tilde bounds,
  conjunctions, and alternatives, or typed construction from Swift ranges.
- Prerelease eligibility rules for range matching, with an option to apply the
  comparisons alone.
- Core and prerelease increments with checked overflow and numeric prerelease
  identifiers of any length.

## Install

Add the package and the `SemVer` product to `Package.swift`:

```swift
dependencies: [
  .package(
    url: "https://github.com/swift-library/swift-semver.git",
    .upToNextMinor(from: "0.1.0")
  ),
],
targets: [
  .target(
    name: "YourTarget",
    dependencies: [
      .product(name: "SemVer", package: "swift-semver"),
    ]
  ),
]
```

## Quick start

Parse a version, check it against a requirement, and compute the next release:

```swift
import SemVer

let minimum = Version(1, 2, 0)
let candidate = try Version(parsing: "1.3.0-rc.1+build.42")

print(candidate > minimum) // true
print(candidate.isPrerelease) // true
print(candidate.description) // 1.3.0-rc.1+build.42

let requirement = try VersionRequirement(parsing: ">=1.2.0 && <2.0.0")
print(requirement.contains(candidate)) // false
print(requirement.contains(candidate.releasing())) // true

print(try candidate.incrementing(.minor)) // 1.4.0
```

The requirement rejects `1.3.0-rc.1` because none of its bounds is a
prerelease. [Prerelease matching](#prerelease-matching) explains the rule.

## Usage

### Parsing versions

`Version("1.2.3")` returns `nil` for invalid input. `try Version(parsing:)`
accepts the same syntax and throws a `Version.ParseError` that names the
problem:

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

A version has exactly three core components, optional prerelease identifiers
after `-`, and optional build metadata after `+`. Prefixes such as `v`,
surrounding whitespace, and missing components are invalid, so `Version("1.2")`
and `Version("v1.2.3")` return `nil`. Core components must fit in a
nonnegative `Int`; numeric prerelease identifiers can have any number of
digits. Identifiers are nonempty and use ASCII letters, digits, and hyphens,
and numeric values have no leading zeros. Error indexes are zero-based within
the core, prerelease, or build metadata list.

To build a version from components, use the memberwise initializer:

```swift
let beta = Version(2, 0, 0, prereleaseIdentifiers: ["beta", "3"], buildMetadataIdentifiers: ["exp"])
print(beta) // 2.0.0-beta.3+exp
```

### Comparing versions

Ordering follows SemVer 2.0.0 precedence. A prerelease sorts before its
release, numeric prerelease identifiers compare numerically, and numeric
identifiers sort before alphanumeric ones:

```swift
let alpha = try Version(parsing: "1.2.3-alpha")
let beta = try Version(parsing: "1.2.3-beta.1")
let release = Version(1, 2, 3)

print(alpha < beta) // true
print(beta < release) // true
print(release.isStable) // true
print(Version(0, 9, 0).isStable) // false
```

`isPrerelease` is true when a version has prerelease identifiers. `isStable`
is true when the major component is positive and the version is not a
prerelease.

Equality, ordering, and hashing ignore build metadata, matching SwiftPM's
version precedence model. Descriptions and `Codable` values keep it:

```swift
let first = try Version(parsing: "1.2.3+first")
let second = try Version(parsing: "1.2.3+second")

print(first == second) // true
print(first.description) // 1.2.3+first
print(Set([first, second]).count) // 1
```

`Codable` encodes a version as a single string. Decoding uses the strict
parser, and a malformed string throws `DecodingError.dataCorrupted` with the
`Version.ParseError` as its underlying error.

### Matching requirements

`VersionRequirement` holds alternatives of comparison groups. Every comparison
in a group must match, and one matching group satisfies the requirement:

```swift
let requirement = try VersionRequirement(parsing: ">=1.2.0 && <2.0.0 || =3.0.0")
print(requirement.contains(Version(1, 3, 0))) // true
print(requirement.contains(Version(2, 1, 0))) // false
print(requirement.contains(Version(3, 0, 0))) // true
```

A comparison is a complete version with an optional operator: `=` or `==` for
exact precedence (the default), `>`, `>=`, `<`, and `<=` for bounds, `^` to keep
the leftmost nonzero component fixed, and `~` to keep major and minor fixed.
`^1.2.3` allows `1.x` from `1.2.3`, `^0.2.3` allows `0.2.x` from `0.2.3`, and
`^0.0.3` allows only `0.0.3`. `*` matches any release version, and the keyword
`empty` matches no version. Whitespace or `&&` joins comparisons, and `||`
separates alternatives. `try VersionRequirement(parsing:)` throws a
`VersionRequirement.ParseError`, which includes the underlying
`Version.ParseError` for a malformed operand.

You can also build requirements from Swift ranges or comparators:

```swift
let range = VersionRequirement(Version(1, 2, 0)..<Version(2, 0, 0))
let closed = VersionRequirement(Version(1, 2, 0)...Version(2, 0, 0))
let alternatives = VersionRequirement(any: [
  [.atLeast(Version(1, 2, 0)), .lessThan(Version(2, 0, 0))],
  [.exact(Version(3, 0, 0))],
])
```

`VersionRequirement.any` matches every release version, and
`VersionRequirement.empty` matches nothing. The description is a canonical
expression, and `Codable` stores that expression as a single string.

### Prerelease matching

By default, `contains(_:)` follows SwiftPM's half-open range behavior. A
comparison group accepts a prerelease only when one of its versions is a
prerelease, and a release-valued exclusive upper bound such as `<2.0.0` also
excludes the prereleases of `2.0.0`. Each alternative applies the rule on its
own. Pass `includingPrereleases: true` to apply the comparisons alone:

```swift
let stable = try VersionRequirement(parsing: ">=1.2.0 && <2.0.0")
let preview = try Version(parsing: "1.3.0-alpha")
print(stable.contains(preview)) // false
print(stable.contains(preview, includingPrereleases: true)) // true

let previews = try VersionRequirement(parsing: ">=1.2.0-alpha && <2.0.0")
let nextMajorPreview = try Version(parsing: "2.0.0-alpha")
print(previews.contains(preview)) // true
print(previews.contains(nextMajorPreview)) // false
```

### Incrementing versions

Increments return a new version and leave the original unchanged:

```swift
let version = try Version(parsing: "1.2.3-alpha.1+build.42")
print(try version.incrementing(.major)) // 2.0.0
print(try version.incrementing(.minor)) // 1.3.0
print(try version.incrementing(.patch)) // 1.2.4
print(try version.incrementingPrerelease()) // 1.2.3-alpha.2
print(try Version(1, 2, 3).incrementingPrerelease()) // 1.2.4-0
print(version.releasing()) // 1.2.3
```

Core increments reset lower components and clear prerelease and build
identifiers. `incrementingPrerelease()` advances the rightmost numeric
prerelease identifier, appends `0` when there is none, and starts the next
patch's prerelease for a release version. `releasing()` keeps the core and
clears both identifier lists. An increment that would exceed `Int.max` throws
`Version.IncrementError.overflow(_:)`.

## Requirements

- Swift 6.0 or later
- iOS 18 or later, macOS 15 or later, and Linux

The system support window currently covers iOS 18, 26, and 27, and macOS 15,
26, and 27. CI runs the tests on macOS with Swift 6.0 and a current compiler,
and on Linux with Swift 6.0. The
[versioning and release policy](Documentation/Architecture/VersioningAndRelease.md)
describes compatibility and maintenance.

## Documentation

- [SemVer module](Sources/SemVer/SemVer.docc/SemVer.md): parsing, comparison,
  build metadata, and the complete API.
- [Matching version requirements](Sources/SemVer/SemVer.docc/Ranges.md):
  expression syntax, 0.x caret bounds, prerelease rules, and serialization.
- [Incrementing versions](Sources/SemVer/SemVer.docc/Incrementing.md): core
  and prerelease increments and overflow errors.
- [Versioning and release policy](Documentation/Architecture/VersioningAndRelease.md)
  and [release guide](Documentation/Reference/ReleaseGuide.md)
- [Changelog](CHANGELOG.md)

## Contributing

Read [CONTRIBUTING.md](CONTRIBUTING.md) before opening a pull request, and run
`Scripts/check` before submitting changes. Report vulnerabilities through the
private route in [SECURITY.md](SECURITY.md). This project follows the
[code of conduct](CODE_OF_CONDUCT.md).

## License

swift-semver is available under the Apache License 2.0 with the Swift
Runtime Library Exception. See [LICENSE.txt](LICENSE.txt) and [NOTICE](NOTICE).

`Version` is adapted from `PackageDescription.Version` in the Swift Package
Manager, copyright Apple Inc. and the Swift project authors. [NOTICE](NOTICE)
records the source revision, the incorporated files, and the changes made.
