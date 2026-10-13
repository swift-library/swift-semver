# Release Guide

Follow the [shared release procedure](https://github.com/swift-library/.github/blob/master/VERSIONING.md#release-procedure)
and the package [compatibility and validation requirements](../Architecture/VersioningAndRelease.md).

Run `Scripts/check` and `Scripts/check-ios --destination <simulator-destination>`
for each maintained iOS simulator generation. Verify the published version with
`Scripts/check-consumer --repository https://github.com/swift-library/swift-semver.git --version X.Y.Z`.
Keep compiler, platform and consumer evidence with the release.
