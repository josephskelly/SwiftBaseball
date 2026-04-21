# Security Policy

## Supported versions

Security fixes land on `main` and are cut into a patch release. Only the
latest minor release line is formally supported.

| Version | Supported |
|---|---|
| latest `0.x` | yes |
| older `0.x` | no |

Once `1.0.0` ships, this table will be updated to reflect the policy for
long-lived major versions.

## Reporting a vulnerability

Please **do not** open a public GitHub issue for a suspected vulnerability.
Email the maintainer at <jskelly84@gmail.com> with:

- A description of the issue and its impact
- Reproduction steps or a minimal PoC
- Your assessment of severity

You should receive an acknowledgement within 72 hours. Fixes for confirmed
high-severity issues will be prioritized over routine work.

## Scope

SwiftBaseball consumes public, unauthenticated endpoints at `statsapi.mlb.com`
and `baseballsavant.mlb.com`. Typical classes of issue we care about:

- Parser-level crashes or undefined behaviour on hostile input
- Request construction that could leak sensitive context (headers, local state)
- Cache poisoning across `SwiftBaseball` configurations
- Concurrency races in shared-state holders (e.g. the `SwiftBaseball.State` lock)

Issues **out of scope**:

- Rate-limiting behaviour of upstream services
- MLB Stats API or Baseball Savant response correctness
- Denial-of-service from intentionally issuing large, legal queries
