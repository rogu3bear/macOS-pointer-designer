# AGENTS.md

Cursor Designer is a shallow monorepo. The current product is the macOS cursor
customization app in `apps/macos`; the root provides identity, documentation,
and boundary checks.

## Read First

- `ANCHOR.md` is the product boundary and invariant doc.
- `NORTH_STAR.md` is the strategy and direction doc.
- `README.md` explains the monorepo layout and root verification commands.
- `apps/macos/README.md` explains the app, helper, architecture, and package
  commands.
- `apps/macos/Sources/PointerDesignerCore/Identity.swift` is mandatory context
  for identity, helper, bundle, launchd, XPC, and settings changes.

## Hard Boundaries

- This repo is Cursor Designer, not WindowDrop.
- Do not import another product's website, deployment metadata, release flow, or
  product copy into this repository.
- There is no canonical Cursor Designer website here yet. Add one only under
  `apps/website` after the domain, release source, and deployment owner are
  confirmed by the operator.
- Keep product/runtime work under `apps/macos` unless the task explicitly
  changes root doctrine or monorepo guardrails.
- Treat identity changes as authority-sensitive. Do not casually rename bundle
  IDs, launchd labels, XPC service names, UserDefaults keys, app-support paths,
  helper labels, cask names, or executable names.

## App Constraints

- Swift and AppKit first.
- The menu bar app and preferences preview should remain useful without a
  helper installed.
- Do not claim system-wide pointer replacement unless the helper path is
  supported, tested, and exposed through the app capability model.
- Do not claim mass-production readiness until the `NORTH_STAR.md` production
  readiness bar is mapped to live evidence.
- Screen recording permission handling must stay honest; do not imply dynamic
  background sampling works without real permission.
- Persisted permission posture is continuity/diagnostics only; live macOS
  permission checks remain authoritative.
- Keep crash recovery, signal handling, orphan cleanup, and cursor restore paths
  conservative and locally testable.
- Preserve the compatibility split: Cursor Designer is the product name, while
  `PointerDesigner` target/executable names remain in use until intentionally
  migrated.

## Canonical Commands

From the monorepo root:

```bash
./scripts/check-monorepo-references.sh
./scripts/check-website-boundary.sh
./scripts/check-distribution-boundary.sh
./scripts/check-compatibility-boundary.sh
./scripts/check-local-first.sh
./scripts/check-app-ui-contract.sh
swift test --package-path apps/macos
```

From `apps/macos`:

```bash
swift build
swift test
make preflight
make release
make dmg
make setup-notary-profile
make notary-profile-check
make release-candidate
make release-artifact-readiness
make release-readiness
```

Use `make preflight` before release or packaging claims because it rebuilds,
runs tests, and validates the generated app bundle with
`Scripts/trust-check.sh`.

Use the release authority targets only when the operator has supplied the
private Apple/notary inputs required for the current release lane. Do not treat
their presence in this file as permission to invent credentials, publish a
release, or claim mass-production readiness.

## Documentation Rules

- Keep `ANCHOR.md` and `NORTH_STAR.md` aligned when product scope, identity, or
  verification posture materially changes.
- Update `apps/macos/README.md` when app behavior, helper behavior, package
  commands, release steps, or troubleshooting change.
- Update root `README.md` when monorepo layout, root verification, or website
  status changes.
- Keep `AGENTS.md` and `CLAUDE.md` aligned on commands, boundaries, and output
  expectations.
- Do not create retrospective evidence logs, changelog notes, or planning
  stacks unless the operator asks for them.

## Agent Workflow

1. Start with live state: `pwd`, branch, HEAD, and dirty tree.
2. Check the quartet: `NORTH_STAR.md`, `ANCHOR.md`, `AGENTS.md`, `CLAUDE.md`.
3. Classify any dirty tree as in-scope, unrelated, shared/other-agent, or
   blocked before editing.
4. Read the smallest relevant app surfaces before changing behavior.
5. Make scoped edits that preserve the product boundary.
6. Run the root boundary, distribution, compatibility, local-first, UI, and
   targeted Swift tests before claiming success.
7. For readiness claims, build a prompt-to-artifact checklist against
   `NORTH_STAR.md` and verify every item with files, commands, or explicit
   blockers.

## Output Contract

Every agent report should include:

- Summary: what changed and why.
- Files touched: every edited path.
- Verification: exact commands run and whether they passed.
- Residual risk: any command skipped, blocked, or intentionally deferred.

Prefer direct local proof over hosted CI narratives.
Keep hosted CI cheap unless the operator explicitly authorizes a release-grade
CI lane.
