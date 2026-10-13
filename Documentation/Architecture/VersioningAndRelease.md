# Versioning and Release

swift-semver follows the [shared release standard](https://github.com/swift-library/.github/blob/master/VERSIONING.md).
`VERSION` declares the library version, `CHANGELOG.md` records release notes,
and `.github/release.json` selects the shared validation and compiler matrix.

## Compatibility surface

The `SemVer` product exposes version parsing, ordering, requirements,
incrementing and Codable representations. Changes to these APIs, serialized
values or compiler and platform requirements affect compatibility.

## Requirements and validation

The package requires Swift 6.0, iOS 15 or macOS 12, and supports Linux.
The maintained system window covers iOS 18/26/27 and macOS 15/26/27.
CI runs compiler checks on macOS with Swift 6.0 and 6.3 and Linux with
Swift 6.0.3 in a digest-pinned image. A separate macOS job checks strict formatting.

`Scripts/check` runs strict formatting, Swift tests, a release build and a
fresh local consumer. `Scripts/check-consumer` also accepts a remote repository
with a revision or next-minor version requirement. `Scripts/check-ios` runs
an independent iOS 15 deployment consumer on an explicitly selected simulator.
Native macOS 27 and the maintained iOS simulator generations are additional
release checks. Evidence belongs in `.build/release-validation`.

README owns installation and usage. The colocated
`Sources/SemVer/SemVer.docc/` catalog owns module and API documentation.
