# Changelog

## Unreleased

- **Breaking**: Require Swift 6.3 or later, iOS 18 or later, and macOS 15 or later.

## 0.1.1

- Lower deployment requirements to iOS 15 and macOS 12.

## 0.1.0

- Provide an immutable, dependency-free `SemVer.Version`, adapted from SwiftPM.
- Parse canonical SemVer strings, compare version precedence and preserve build metadata in descriptions and Codable values.
- Support numeric prerelease identifiers beyond the range of machine integers.
- Report structured parsing errors for malformed identifiers, leading zeroes and core component overflow.
- Expose prerelease and stable version status, with parsing diagnostics preserved by Codable decoding.
- Match typed and parsed version requirements with comparison groups, alternatives, caret/tilde bounds, an empty requirement and SwiftPM-style prerelease eligibility.
- Increment core components with overflow diagnostics, advance arbitrary-length prerelease numbers and promote prereleases to release versions.
