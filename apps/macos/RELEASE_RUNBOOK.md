# Cursor Designer Release Runbook

This runbook is the app-first path from a clean checkout to a public Cursor
Designer release decision. It does not make the product available by itself.
Cursor Designer is not mass-production ready until every command and manual
observation below passes against the same signed, notarized,
Gatekeeper-accepted DMG.

Do not create or publish a website while this runbook is red. A website is
downstream of a verified app artifact, stable GitHub release metadata, and a
truthful download path.

## Inputs

- A clean `main` checkout.
- A Developer ID Application signing identity.
- A notarytool keychain profile.
- Access to publish a stable GitHub release in `rogu3bear/macOS-pointer-designer`.
- A macOS machine that can perform the human checks in
  `MANUAL_RELEASE_CHECKS.md`.

Do not commit Apple IDs, app-specific passwords, API keys, certificates,
private keys, keychains, provisioning profiles, notarization output, or manual
release evidence that contains secrets.

Current release-authority blockers are tracked in GitHub issue #71:
https://github.com/rogu3bear/macOS-pointer-designer/issues/71
Keep that issue open until this runbook's final audit passes.

## Current Blocker Check

Run this first:

```bash
make notary-profile-check NOTARY_PROFILE="<notarytool profile>"
```

If it fails, create the profile interactively:

```bash
xcrun notarytool store-credentials "<notarytool profile>" \
  --apple-id <apple-id> \
  --team-id <team-id>
```

Omit `--password` so `notarytool` prompts for the app-specific password instead
of putting it in shell history. If the team uses an App Store Connect API key,
store the profile with `--key` and `--key-id` from a private operator machine
path; add `--issuer` for team API keys. Do not copy the key into this
repository.

The repo also provides a wrapper that stores and immediately verifies the
profile from private environment variables:

```bash
NOTARY_KEY_PATH="/private/path/AuthKey_XXXXXXXXXX.p8" \
NOTARY_KEY_ID="XXXXXXXXXX" \
NOTARY_ISSUER_ID="00000000-0000-0000-0000-000000000000" \
make setup-notary-profile NOTARY_PROFILE="<notarytool profile>"
```

`NOTARY_ISSUER_ID` is optional for individual API keys and required for team
API keys.

For Apple ID auth, set `NOTARY_APPLE_ID` and `NOTARY_TEAM_ID`, then run the
target interactively so `notarytool` prompts securely. Use
`NOTARY_APP_SPECIFIC_PASSWORD` only from a private automation environment:
this `notarytool` build has no password-stdin mode, so the wrapper must pass
that value to `notarytool --password`. Do not paste app-specific passwords
into committed docs.

`notarytool` does not expose a profile-list command in its help surface; use the
exact profile name you created with `store-credentials` or create a new one.

Then rerun the check. Do not proceed to release-candidate work until it passes.

## Machine Gates

From `apps/macos`, run:

```bash
make signing-identity-check SIGN_IDENTITY="<Developer ID Application identity>"
make release-candidate \
  SIGN_IDENTITY="<Developer ID Application identity>" \
  NOTARY_PROFILE="<notarytool profile>"
make release-readiness NOTARY_PROFILE="<notarytool profile>"
```

`make release-candidate` builds, signs, notarizes, staples, and runs artifact
readiness. `make release-readiness` additionally verifies stable GitHub release
metadata, so it must remain red until a stable GitHub release exists and its
DMG digest matches the local DMG.

## Stable GitHub Release

Publish a stable GitHub release only after the signed and notarized local
candidate exists. The stable release tag must match the app version from
`CursorDesigner.app`, and the release metadata must expose the SHA-256 digest
for `CursorDesigner.dmg`.

Verify it with:

```bash
make release-metadata-check
make release-readiness NOTARY_PROFILE="<notarytool profile>"
```

## Manual Evidence

After `make release-readiness` passes, perform every row in
`MANUAL_RELEASE_CHECKS.md` against the same Gatekeeper-accepted DMG. Record the
observed values using that file's evidence template.

Generate the starting evidence record from the current artifact so the commit,
DMG digest, mounted app identity, app version, app build, and executable SHA-256
are not hand-copied:

```bash
make manual-release-evidence-template RELEASE_TAG="<stable tag>" > ReleaseEvidence/manual-release-evidence.txt
```

Then verify the evidence is complete and bound to the artifact:

```bash
make manual-release-evidence-check MANUAL_EVIDENCE="<completed evidence file>"
```

The evidence check compares the recorded commit, release tag, DMG filename,
DMG SHA-256, mounted app bundle ID, app version, app build, and executable
SHA-256 to the local artifact under assessment.

## Final Audit

Only after the machine gates, stable release metadata, and manual evidence pass,
run:

```bash
make north-star-audit \
  NOTARY_PROFILE="<notarytool profile>" \
  MANUAL_EVIDENCE="<completed evidence file>"
```

The release can be described as mass-production ready only if this final audit
passes on the same commit and DMG.

## Stop Conditions

Stop and do not publish if any of these are true:

- Gatekeeper rejects the app or DMG.
- The DMG is not notarized or stapled.
- The stable GitHub release digest does not match the local DMG.
- Manual Screen Recording, persistence, drag-install, or local-first checks are
  missing or fail.
- Any docs or UI imply Homebrew, stable download, system-wide pointer
  replacement, cloud processing, automation, or production readiness beyond
  the verified artifact.
