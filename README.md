# swift-semver

Immutable semantic versions, range requirements and version increments.
The version core is adapted from SwiftPM's `PackageDescription.Version`.
The `SemVer` product and module use the Swift standard library with zero external dependencies.
It provides strict parsing with structured errors, SemVer precedence and complete
string serialization. Requirements add comparison groups and explicit prerelease
matching rules; increments return new versions with checked core arithmetic.

```swift
import SemVer

let minimum = Version(1, 2, 0)
if let version = Version("1.3.0-rc.1+build.42") {
  print(version > minimum) // true
  print(version.description) // 1.3.0-rc.1+build.42
}
```

## Semantics

`Version` supports `Sendable`, `Comparable`, `Hashable`, `Codable` and
`LosslessStringConvertible`. Parsing follows SemVer 2.0.0 syntax: three core
components, optional prerelease identifiers and optional build metadata. Core
components must fit in a nonnegative Swift `Int`. Numeric prerelease identifiers
have no integer size limit.

Equality, ordering and hashing ignore build metadata, matching SwiftPM's version
precedence model. Descriptions and single-string Codable values preserve it.
`Version("1.2")`, `Version("v1.2.3")` and invalid syntax return `nil`.

## Parsing and prereleases

Use `try Version(parsing:)` when invalid input needs a diagnostic. It accepts the
same syntax as the failable initializer and throws `Version.ParseError`, identifying
the invalid component, leading zero or integer overflow.

```swift
let preview = try Version(parsing: "1.2.3-alpha.1+build.42")
print(preview.isPrerelease) // true
print(preview < Version(1, 2, 3)) // true
print(Version(1, 2, 3).isStable) // true
```

Prerelease identifiers can use names such as `alpha`, `beta` and `rc`, with
dot-separated identifiers for iteration numbers. `isStable` is true when the
major component is positive and prerelease identifiers are absent.

## Range requirements

```swift
let requirement = try VersionRequirement(parsing: ">=1.2.0 && <2.0.0")
print(requirement.contains(Version(1, 3, 0))) // true
print(requirement.contains(preview)) // false
print(requirement.contains(preview, includingPrereleases: true)) // true

let range = VersionRequirement(Version(1, 2, 0)..<Version(2, 0, 0))
```

Use `empty` for a requirement that matches no version. Use complete versions with `=`, `==`, `>`, `>=`, `<`, `<=`, `^`, `~` or `*`.
Whitespace or `&&` joins comparisons; `||` separates alternatives. Caret (`^`)
keeps the leftmost nonzero component fixed; tilde (`~`) keeps major and minor fixed.

Default half-open range matching follows SwiftPM: prereleases require an explicit
prerelease boundary, and a release-valued exclusive upper bound excludes that
core's prereleases. Each alternative evaluates this independently. The
[range documentation](Sources/SemVer/SemVer.docc/Ranges.md) covers 0.x bounds,
typed comparisons, encoding and prerelease examples.

## Incrementing versions

```swift
let version = Version(1, 2, 3)
print(try version.incrementing(.minor)) // 1.3.0
print(try preview.incrementingPrerelease()) // 1.2.3-alpha.2
print(preview.releasing()) // 1.2.3
```

Core increments reset lower components and clear prerelease and build identifiers.
Prerelease increments advance the rightmost numeric identifier without an integer
size limit. `releasing()` keeps the core and clears both identifier lists. The
[increment documentation](Sources/SemVer/SemVer.docc/Incrementing.md) describes
starting prereleases and overflow errors.

The [module documentation](Sources/SemVer/SemVer.docc/SemVer.md) covers the complete API.

## Requirements and validation

Swift tools 6.0+, iOS 18+ and macOS 15+. Compiler requirements and the three-generation
Apple system window are reviewed independently. The core implementation is portable
Swift; Linux compiler checks run in CI.

```sh
Scripts/check
```

See the [version and release policy](Documentation/Architecture/VersioningAndRelease.md),
[release guide](Documentation/Reference/ReleaseGuide.md) and
[contribution guide](CONTRIBUTING.md). The initial version is `0.1.0`; installation
from a version requirement becomes available after its first GitHub release.

## License and source

Apache License 2.0 with the Swift Runtime Library Exception
(`Apache-2.0 WITH Swift-exception`). [LICENSE.txt](LICENSE.txt) contains the full terms.
[NOTICE](NOTICE) records the upstream revision, incorporated files and maintained changes.
