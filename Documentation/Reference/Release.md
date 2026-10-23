# Release

The shared workflows validate the package and publish GitHub releases from
signed version tags. [`.github/swift-package.json`](../../.github/swift-package.json)
declares validation; [`.github/release.json`](../../.github/release.json)
declares release fields.

Version rules for swift-semver, covering tags, release timing, choosing the
next version and the changelog, are in
[VERSIONING](https://github.com/swift-library/.github/blob/master/VERSIONING.md).
This document records the repository's release facts and mechanics and does
not restate those rules.

README owns installation and usage. The colocated
`Sources/SemVer/SemVer.docc/` catalog owns module and API documentation.

## Components and Version Sources

| Shipped component | Version meaning | Version source | Mirrors and derived fields | Update and read-only check |
| --- | --- | --- | --- | --- |
| `SemVer` library | Library version | [`VERSION`](../../VERSION); release notes: [`CHANGELOG.md`](../../CHANGELOG.md), both selected by [`.github/release.json`](../../.github/release.json). | Not established. | The shared policy and release workflows validate the version and changelog. |

## Compatibility Surface

The `SemVer` product exposes version parsing, ordering, requirements,
incrementing and Codable representations. Changes to these APIs, serialized
values or compiler and platform requirements affect compatibility.

## Dependencies and Verified Combinations

The package requires Swift 6.0, iOS 15 or macOS 12, and supports Linux.
The maintained system window covers iOS 18/26/27 and macOS 15/26/27.
[`.github/swift-package.json`](../../.github/swift-package.json) selects the
compiler and platform matrix. CI runs tests and release builds on macOS with
Swift 6.0 and 6.3, and tests on Linux with Swift 6.0.3 in a digest-pinned image.
The Apple platform job builds `SemVer` for iOS and runs its tests on a simulator
matching the selected Xcode SDK. Formatting and the `SemVer` DocC catalog use
the last declared compiler.

## Derived Metadata and Drift Checks

The shared workflow runs strict formatting over `Package.swift`, `Sources` and
`Tests`, and builds the DocC catalog with warnings as errors. The required
checks are `policy / policy` and `validate / result`; the validation aggregate
requires every declared job to succeed.

## Candidate, Acceptance and Publication

Run the [local validation commands](../../CONTRIBUTING.md#local-validation),
then require the policy and validation checks to pass on the accepted commit.

Pushing its signed annotated `vX.Y.Z` tag starts the
[`Release`](../../.github/workflows/release.yml) workflow. It validates the
tagged commit, verifies the tag, version and changelog, then publishes the
changelog notes as the GitHub release.

## Entry Points and Artifact Retention

| Operation | Existing command or explicit manual procedure | Required access |
| --- | --- | --- |
| Version update and check | Update `VERSION` and `CHANGELOG.md` under VERSIONING; the shared policy workflow checks them. | Repository write access. |
| Candidate validation and build | [Local validation commands](../../CONTRIBUTING.md#local-validation); CI runs the declared shared jobs. | Swift toolchain and `xcrun swift-format`. |
| iOS simulator validation | The shared Apple platform job builds and tests the `swift-semver` scheme. | Xcode and its matching iOS simulator runtime. |
| Status and interrupted-run recovery | Not established. | Not established. |
| Acceptance and publication | Push the accepted signed version tag to run [`Release`](../../.github/workflows/release.yml). | Repository write access and the maintainer's signing key. |
| Cleanup | Remove local build outputs when no longer needed. | Local filesystem access. |

Local build outputs live in `.build/`.
