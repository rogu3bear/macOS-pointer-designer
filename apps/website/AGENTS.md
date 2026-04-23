# AGENTS.md

This directory contains the WindowDrop website surface inside the Cursor Designer monorepo. Keep work scoped to `apps/website`, its docs, and its runtime surfaces here; do not drift into `apps/macos` unless the task explicitly spans both.

## Scope

- `site/` is the maintained website app.
- `docs/` and `ops/` hold the current website runbooks and content/style guidance.
- `site/src/bin/server.rs` is the checked-in SSR/static server surface for the site.
- `site/src/pages/` includes the live legal/compliance routes such as privacy, privacy choices, terms, and accessibility.
- Do not document or modify the macOS app from this directory unless the task explicitly spans both products.

## Canonical Commands

- Setup: `cd site && ./scripts/setup.sh`
- Dev: `cd site && ./scripts/run.sh`
- Build: `cd site && ./scripts/build-release.sh`
- Check: `cd site && cargo check --features ssr --all-targets`
- Verify: `cd site && ./verify.sh`

## Guardrails

- Keep copy factual, calm, and accessible.
- Preserve the current site/runtime posture. Static assets are primary, but the checked-in SSR server is real; do not describe the repo as static-only when the server path is in play.
- Do not invent extra backend services, analytics, or trackers.
- Keep `docs/architecture.md`, `docs/test-plan.md`, and `docs/content-style.md` aligned with actual site behavior, including the legal/compliance pages under `site/src/pages/`.
- Keep runtime claims aligned with `site/src/bin/server.rs`, not old launchd/tunnel-only lore.
- Remove stale operational lore instead of stacking more exception notes on top.
