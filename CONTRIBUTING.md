# Contributing to SwiftBaseball

Thanks for your interest in contributing. SwiftBaseball aims to be the
Swift-native analogue of pybaseball, scoped to the MLB Stats API and
Baseball Savant as its only data sources. Contributions that expand
coverage of those two sources, improve type safety, add tests, or
sharpen the documentation are all welcome.

## Getting set up

```
git clone https://github.com/josephskelly/SwiftBaseball.git
cd SwiftBaseball
swift build
swift test
```

Requirements:

- Swift 6.0 or newer (Swift 6 language mode is enforced)
- macOS 14 / iOS 17 / iPadOS 17 / tvOS 17 / watchOS 10 / visionOS 1, or Linux

Optional dev tooling (installed via Homebrew):

```
brew install swiftlint swiftformat
```

## Workflow

1. Open an issue first for anything larger than a typo fix or a small
   bug. For new endpoints, use the **Endpoint request** issue template —
   include the MLB Stats API or Baseball Savant URL, the fluent API you'd
   propose, and a sample JSON or CSV payload.
2. Create a feature branch from `main`.
3. Commit in logical units; subject lines imperative and ≤72 chars.
4. Run the full pre-PR checklist (below) locally.
5. Open a PR against `main`. Fill in the template. Link the issue.

## Pre-PR checklist

Every PR must pass:

- [ ] `swift build` — clean on macOS
- [ ] `swift build --configuration release` — clean on macOS
- [ ] `swift test` — all tests pass
- [ ] `swiftlint lint --strict` — no violations
- [ ] `swiftformat --lint Sources Tests` — no drift
- [ ] Every new public symbol has a DocC `///` comment
- [ ] `CHANGELOG.md` Unreleased section updated
- [ ] README.md reflects any user-visible behavior change

## Adding a new endpoint

1. Drop a fixture into `Tests/SwiftBaseballTests/Fixtures/` captured from
   the real API (or CSV, for Savant).
2. Add the raw Codable mirror in `Sources/SwiftBaseball/Internal/MLBAPIResponses.swift`
   (or the Savant equivalent).
3. Add the converter in `MLBResponseConverters.swift` that maps the
   internal type onto a public model.
4. Add the public model to `Sources/SwiftBaseball/Models/`.
5. Add the endpoint builder in `Sources/SwiftBaseball/Endpoints/`.
6. Expose the fluent entry point on the `SwiftBaseball` namespace in
   `SwiftBaseball.swift`.
7. Add unit tests with the fixture and an env-gated integration test in
   `IntegrationTests/`.

## Swift Package Index submission

SwiftBaseball is (or will be) listed on [Swift Package Index](https://swiftpackageindex.com).
If you're the maintainer preparing a release, verify the SPI compatibility
grid for the tag before publishing. The one-time submission is a PR to
[SwiftPackageIndex/PackageList](https://github.com/SwiftPackageIndex/PackageList)
adding the repo URL to `packages.json`.

## Code style

- Follow the Swift API Design Guidelines — clarity at the point of use.
- Prefer value types (`struct`) over reference types.
- Every public declaration carries a DocC comment. Use `/// - Parameters:`,
  `/// - Returns:`, `/// - Throws:` where they add information.
- No force unwraps in production code.
- No third-party runtime dependencies. Foundation and URLSession only.
- `async throws` for every public query method.
- `Sendable` on every public type.

## Reporting bugs

Use the **Bug report** issue template and include:

- SwiftBaseball version or commit SHA
- Swift toolchain and OS
- The fluent query or snippet that triggers the bug
- The expected vs observed behavior
- For decoding bugs, a fixture JSON/CSV sample if possible

## Security

See [SECURITY.md](SECURITY.md) for how to report a security issue privately.

## License

By contributing you agree that your contributions are licensed under the
same [MIT License](LICENSE) that covers the project.
