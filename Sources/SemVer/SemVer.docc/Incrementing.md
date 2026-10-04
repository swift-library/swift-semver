# Incrementing versions

Advance core components, iterate prereleases or promote a version to a release.

## Core increments

```swift
let version = try Version(parsing: "1.2.3-alpha.1+build.42")
print(try version.incrementing(.major)) // 2.0.0
print(try version.incrementing(.minor)) // 1.3.0
print(try version.incrementing(.patch)) // 1.2.4
```

Core increments always add one to the selected ``Version/Component``. Incrementing
major resets minor and patch to zero; incrementing minor resets patch. Every
core increment clears prerelease and build metadata. The original value remains
unchanged.

If the selected component is Int.max, the operation throws
``Version/IncrementError/overflow(_:)``. Lower components can be Int.max when an
operation resets them; no arithmetic is performed on those components.

## Prerelease increments

```swift
let alpha = try Version(parsing: "1.2.3-alpha.1+build.42")
print(try alpha.incrementingPrerelease()) // 1.2.3-alpha.2
print(try Version(parsing: "1.2.3-alpha").incrementingPrerelease()) // 1.2.3-alpha.0
print(try Version(1, 2, 3).incrementingPrerelease()) // 1.2.4-0
```

For an existing prerelease, the rightmost numeric identifier increases by one.
Other identifiers retain their order and values; if none is numeric, "0" is
appended. Numeric identifiers can contain arbitrarily many digits, and incrementing
them cannot overflow a machine integer. Build metadata is cleared.

A release version starts the next patch's prerelease with the identifier "0".
Starting that next patch can throw a patch overflow error. An existing prerelease
can still advance its identifiers when its patch component is Int.max.

Use the component initializer to start a named prerelease series:

```swift
let beta = Version(1, 3, 0, prereleaseIdentifiers: ["beta", "1"])
print(try beta.incrementingPrerelease()) // 1.3.0-beta.2
```

## Promoting a release

```swift
let candidate = try Version(parsing: "1.2.3-rc.1+build.42")
print(candidate.releasing()) // 1.2.3
```

The releasing method preserves major, minor and patch and clears both identifier
lists. It is idempotent and does not require arithmetic. Increment operations
compute versions; the caller chooses which operation suits its compatibility
and release policy.
