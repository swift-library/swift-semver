# Contributing

By submitting a contribution, you confirm your right to license it under
[the package license](LICENSE.txt).

External contributions are welcome. Use a Conventional Commit PR title and
follow `.swift-format`. Maintainers follow the shared
[signing instructions](https://github.com/swift-library/.github/blob/master/MAINTENANCE.md#signing).
Review the
[release reference](Documentation/Reference/Release.md)
when changing compatibility, requirements or release inputs.

## Local validation

Use Swift 6.3 or later. Shared CI uses Xcode 26.6 on macOS 26 for its single
compiler entry and Apple platform checks.

Run these commands before opening a pull request:

```sh
swift build
swift test
swift build -c release
swift format lint --strict --configuration .swift-format --recursive Package.swift Sources Tests
```

[`.github/swift-package.json`](.github/swift-package.json) declares the CI
compiler, platforms and DocC target. Formatting defaults to `Package.swift`,
`Sources` and `Tests`. The required checks are `policy / policy` and
`validate / result`.
