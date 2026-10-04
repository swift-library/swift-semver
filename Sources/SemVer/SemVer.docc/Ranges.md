# Matching version requirements

Express version bounds and choose how prerelease candidates match.

## Overview

``VersionRequirement`` stores alternatives of comparison groups. Every comparison
in a group must match; one matching group satisfies the requirement. The type
supports Sendable, Hashable, LosslessStringConvertible and string Codable.

## Requirement expressions

```swift
let requirement = try VersionRequirement(parsing: ">=1.2.0 && <2.0.0 || =3.0.0")
print(requirement.contains(Version(1, 3, 0))) // true
print(requirement.contains(Version(2, 1, 0))) // false
print(requirement.contains(Version(3, 0, 0))) // true
```

Whitespace or `&&` joins comparisons; `||` separates alternatives. A comparison
operator can touch its version or be separated by whitespace. Version operands
use the complete strict syntax accepted by ``Version``.

| Expression | Meaning |
| --- | --- |
| `1.2.3`, `=1.2.3`, `==1.2.3` | Exact version precedence |
| `>1.2.3`, `>=1.2.3` | Exclusive or inclusive lower bound |
| `<2.0.0`, `<=2.0.0` | Exclusive or inclusive upper bound |
| `^1.2.3` | At least 1.2.3, with major fixed at 1 |
| `^0.2.3` | At least 0.2.3, with major/minor fixed at 0.2 |
| `^0.0.3` | At least 0.0.3, with major/minor/patch fixed at 0.0.3 |
| `~1.2.3` | At least 1.2.3, with major/minor fixed at 1.2 |
| `*` | Any release version by default |
| `empty` | No version, including prereleases |

Caret bounds fix the leftmost nonzero core component and all components before
it; when the entire core is zero, they fix all three components. This gives 0.x
caret requirements a narrower window than SwiftPM's upToNextMajor requirement.
Tilde bounds fix major and minor. Both check components directly, so bounds at
Int.max do not overflow while calculating a next version.

The failable initializer returns nil for malformed expressions. The throwing
initializer reports ``VersionRequirement/ParseError``, including an underlying
``Version/ParseError`` for malformed version operands. Diagnostic token indexes
are zero-based; whitespace separates tokens and each `&&` or `||` is its own token.

## Constructing requirements in Swift

```swift
let range = VersionRequirement(Version(1, 2, 0)..<Version(2, 0, 0))
let closed = VersionRequirement(Version(1, 2, 0)...Version(2, 0, 0))
let alternatives = VersionRequirement(any: [
  [.atLeast(Version(1, 2, 0)), .lessThan(Version(2, 0, 0))],
  [.exact(Version(3, 0, 0))],
])
```

Use init(all:) for one comparison group or init(any:) for alternatives of groups.
An empty group matches any release version. An empty list of alternatives is
``VersionRequirement/empty`` and matches no version. Its expression is the standalone
keyword `empty`; an empty input string is invalid. Contradictory comparisons are
valid requirements that match no version.

## Prerelease matching

Default half-open range behavior follows
[SwiftPM's version sets](https://github.com/swiftlang/swift-package-manager/blob/cf583daa3d7083fb1d599bbdfe973e886c16e2f5/Sources/PackageGraph/VersionSetSpecifier.swift)
and their prerelease-aware range membership:

- A group with only release-valued comparisons excludes prereleases.
- A prerelease comparison explicitly enables prerelease candidates for that group,
  including candidates with a different core that still satisfy the comparisons.
- A release-valued exclusive upper bound excludes prereleases of that upper core.

| Requirement | Candidate | Default match |
| --- | --- | --- |
| `>=1.2.0 && <2.0.0` | `1.3.0-alpha` | false |
| `>=1.2.0-alpha && <2.0.0` | `1.3.0-alpha` | true |
| `>=1.2.0-alpha && <2.0.0` | `2.0.0-alpha` | false |
| `>=1.2.0 && <2.0.0-beta` | `2.0.0-alpha` | true |
| `=1.3.0-alpha` | `1.3.0-alpha` | true |

Each alternative applies this rule independently, so a prerelease bound in one
alternative does not enable prereleases in the others. For an inclusive upper
bound, comparison ordering determines whether the upper core's prereleases match
after the group has enabled prereleases. The wildcard excludes prereleases by
default as well.

```swift
let requirement = try VersionRequirement(parsing: ">=1.2.0 && <2.0.0")
let preview = try Version(parsing: "1.3.0-alpha")
print(requirement.contains(preview)) // false
print(requirement.contains(preview, includingPrereleases: true)) // true
```

With includingPrereleases enabled, only the comparisons apply. In a `<2.0.0`
comparison this allows `2.0.0-alpha`, because its precedence is below 2.0.0.
Caret and tilde retain their fixed-component bounds in both modes.

## Serialization and identity

The description normalizes exact comparisons to `=`, conjunctions to `&&` and
alternatives to `||`, preserving bound metadata. Codable uses that complete
expression as a single string. Invalid decoding retains the parsing error as
the underlying error and preserves the coding path.

Equality and hashing compare the stored comparison groups and their order;
equivalent expressions with different groups need not be equal. Bound equality
ignores build metadata, just as version equality does.
