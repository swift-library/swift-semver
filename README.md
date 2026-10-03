# swift-semver

An immutable semantic version type, adapted from SwiftPM's `PackageDescription.Version`.
The `SemVer` product and module use the Swift standard library with zero external dependencies.

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
