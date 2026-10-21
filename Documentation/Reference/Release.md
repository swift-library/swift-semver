# Release

Release status: partly manual; local validation is implemented in
[`Scripts/check`](../../Scripts/check), and
[`Scripts/check-ios`](../../Scripts/check-ios) requires an explicit simulator
destination.

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
| `SemVer` library | Library version | [`VERSION`](../../VERSION); release notes: [`CHANGELOG.md`](../../CHANGELOG.md), both selected by [`.github/release.json`](../../.github/release.json). | Not established. | Not established. |

## Compatibility Surface

The `SemVer` product exposes version parsing, ordering, requirements,
incrementing and Codable representations. Changes to these APIs, serialized
values or compiler and platform requirements affect compatibility.

## Dependencies and Verified Combinations

The package requires Swift 6.0, iOS 15 or macOS 12, and supports Linux.
The maintained system window covers iOS 18/26/27 and macOS 15/26/27.
[`.github/release.json`](../../.github/release.json) selects the shared
validation and compiler matrix. CI runs compiler checks on macOS with
Swift 6.0 and 6.3 and Linux with Swift 6.0.3 in a digest-pinned image.
A separate macOS job checks strict formatting.

## Derived Metadata and Drift Checks

`Scripts/check` runs strict formatting, Swift tests, a release build and a
fresh local consumer. `Scripts/check-consumer` also accepts a remote repository
with a revision or next-minor version requirement. `Scripts/check-ios` runs
an independent iOS 15 deployment consumer on an explicitly selected simulator.

## Candidate, Acceptance and Publication

Run `Scripts/check`. Additional release checks cover native macOS 27 and
each maintained iOS simulator generation; run `Scripts/check-ios` with an
explicit destination for each generation.

Verify the published version with the remote consumer command in
[Entry Points and Artifact Retention](#entry-points-and-artifact-retention).

## Evidence Reuse and Invalidation

Keep compiler, platform and consumer evidence with the release.

## Entry Points and Artifact Retention

| Operation | Existing command or explicit manual procedure | Required access |
| --- | --- | --- |
| Version update and check | Not established. | Not established. |
| Candidate validation and build | `Scripts/check` | Swift toolchain and `xcrun swift-format`. |
| iOS simulator validation | `Scripts/check-ios --destination <simulator-destination>` | Xcode and an explicitly selected simulator. |
| Status and interrupted-run recovery | Not established. | Not established. |
| Acceptance and publication | Verify the published version with `Scripts/check-consumer --repository https://github.com/swift-library/swift-semver.git --version X.Y.Z`. | Swift toolchain and remote repository access. |
| Cleanup | Not established. | Not established. |

Evidence belongs in `.build/release-validation`.
