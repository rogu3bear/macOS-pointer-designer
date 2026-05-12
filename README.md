# Cursor Designer Monorepo

This repository contains the Cursor Designer product surfaces as a shallow monorepo.

## Layout

```text
apps/
  macos/    Swift package for the macOS app and helper
```

## Doctrine

Start with the repository contract before changing product scope, identity,
release posture, or website status:

- `NORTH_STAR.md` defines the pointer-first product promise, production
  readiness bar, website standard, and final audit gates.
- `ANCHOR.md` captures stable product, identity, architecture, safety, and
  operational invariants.
- `AGENTS.md` and `CLAUDE.md` define the local agent workflow, boundaries, and
  proof expectations.

## macOS App

The macOS app lives in `apps/macos`.

```bash
cd apps/macos
swift test
swift build
```

## Release Status

Cursor Designer is not advertised as a stable public download yet. A signed
local DMG is not enough for release: `make north-star-audit` must pass against
the same notarized, stapled, Gatekeeper-accepted artifact, stable release
metadata, and completed manual release evidence before any mass-production
claim.

From `apps/macos`, the release authority lane starts with
`make setup-notary-profile` and `make notary-profile-check`, then proceeds
through `make release-candidate`, `make release-artifact-readiness`, and
`make release-readiness` against the same artifact.

Use one private credential lane to create the local notary profile. For an App
Store Connect API key:

```bash
cd apps/macos
NOTARY_KEY_PATH="/private/path/AuthKey_XXXXXXXXXX.p8" \
NOTARY_KEY_ID="XXXXXXXXXX" \
NOTARY_ISSUER_ID="00000000-0000-0000-0000-000000000000" \
make setup-notary-profile NOTARY_PROFILE="notarization"
```

For Apple ID auth, run the target interactively so `notarytool` prompts for the
app-specific password instead of putting it in shell history:

```bash
cd apps/macos
NOTARY_APPLE_ID="you@example.com" \
NOTARY_TEAM_ID="4JB58L7BTZ" \
make setup-notary-profile NOTARY_PROFILE="notarization"
```

Do not commit Apple IDs, app-specific passwords, API keys, key IDs, issuer IDs,
Keychain exports, or completed release evidence containing secrets.

## Website

There is no canonical Cursor Designer website in this repository yet.

Do not import or operate another product's website as the Cursor Designer
website. A future Cursor Designer website should start as a Cursor
Designer-specific surface under `apps/website` only when its domain, release
source, and deployment owner are confirmed.

When those prerequisites are satisfied, use the operator's Leptos Cloudflare
template as the technical base only. Do not scaffold a generic SaaS site,
placeholder launch page, fake download page, or marketing surface that outruns
the verified app and release artifact.

Use template capabilities only for the Cursor Designer job: static-first
Leptos UI, Cloudflare edge delivery, verified release metadata reads, digest
display, compatibility notes, and privacy-preserving download routing. Do not
add accounts, dashboards, analytics, server-side personalization, or background
jobs just because the template can support them.

## Verification

Run the product checks from the monorepo root:

```bash
./scripts/check-monorepo-references.sh
./scripts/check-website-boundary.sh
./scripts/check-distribution-boundary.sh
./scripts/check-compatibility-boundary.sh
./scripts/check-local-first.sh
./scripts/check-app-ui-contract.sh
swift test --package-path apps/macos
```
