# Usage guide

## Parsing versions

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

## Comparing versions

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

## Matching requirements

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

## Prerelease matching

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

## Incrementing versions

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

