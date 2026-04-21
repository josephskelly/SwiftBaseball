<!--
Thanks for contributing to SwiftBaseball! Please fill in each section.
Delete sections that do not apply, but do not delete the checklist.
-->

## Summary

<!-- 1–3 sentences. What does this PR change and why? -->

## Linked issues

<!-- e.g. Closes #123, Refs #456. Every non-trivial PR should link an issue. -->

## Type of change

- [ ] Bug fix
- [ ] New endpoint coverage
- [ ] New feature (non-endpoint)
- [ ] Refactor / internal cleanup
- [ ] Documentation
- [ ] Test-only change
- [ ] CI / tooling

## Public API impact

<!--
If this PR changes any public symbol (added, removed, renamed, re-typed,
or altered signature), describe the change and its migration story.
Write "None" if the PR is internal-only.
-->

## Test plan

<!--
What did you run locally? For endpoint work, include both the unit test
using the fixture and (if applicable) the env-gated integration test.
-->

- [ ] `swift build`
- [ ] `swift build --configuration release`
- [ ] `swift test`
- [ ] Integration tests run with `SWIFTBASEBALL_INTEGRATION=1` (if applicable)

## Pre-PR checklist

- [ ] `swiftlint lint --strict` — no violations
- [ ] `swiftformat --lint Sources Tests` — no drift
- [ ] Every new public symbol has a DocC `///` comment
- [ ] `CHANGELOG.md` Unreleased section updated
- [ ] `README.md` reflects any user-visible behavior change
- [ ] New endpoints ship with a captured fixture in `Tests/SwiftBaseballTests/Fixtures/`

## Screenshots / output

<!-- Optional: CLI output, decoded model snippets, DocC preview, etc. -->
