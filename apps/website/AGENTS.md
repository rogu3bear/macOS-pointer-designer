# AGENTS.md

This directory contains the WindowDrop website surface inside the Cursor Designer monorepo. Treat it as a website/runtime surface with an optional SSR checkout path, not as generic app code and not as a pure static brochure.

## Scope Boundaries

- Website content, presentation, and runtime work live here under `site/`, `docs/`, and `ops/`.
- Keep work scoped to `apps/website` unless the task explicitly spans `apps/macos` too.
- Do not change Cloudflare account settings, DNS, or external email setup from here unless explicitly requested.
- Do not add analytics, trackers, or extra backend services without instruction.

## Current Stack

- Rust + Leptos site in `site/`
- Trunk for browser bundle generation
- Axum server/runtime path for checkout, purchase verification, and recovery flows
- Plain CSS
- Cloudflare Pages/static hosting only for the static or `SITE_LIFETIME_MODE=in-app` path

## Canonical Commands

- Setup: `cd site && ./scripts/setup.sh`
- Dev wrapper: `cd site && ./scripts/run.sh`
- Direct dev server: `cd site && trunk serve`
- Release build: `cd site && ./scripts/build-release.sh`
- Repo verification: `cd apps/website && ./ops/verify.sh`
- Local health check: `curl http://127.0.0.1:3410/healthz`

## Runtime Truth

- The site supports both in-app and web checkout modes.
- Web checkout requires the Axum server runtime plus Stripe and license-signing configuration.
- Static-only Pages hosting cannot serve checkout verification or recovery APIs.
- Legal/compliance pages under `site/src/pages/` are active runtime surface and should stay reflected in docs and footer/header guidance.
- Keep CTA, pricing, checkout, and unlock documentation aligned with the active runtime mode instead of describing the repo as content-only.

## Documentation Duties

- Update [`docs/architecture.md`](docs/architecture.md), [`docs/test-plan.md`](docs/test-plan.md), and [`docs/content-style.md`](docs/content-style.md) when site behavior changes.
- Keep web purchase and unlock guidance aligned with [`docs/in-app-unlock-setup.md`](docs/in-app-unlock-setup.md) and [`ops/stripe-setup.sh`](ops/stripe-setup.sh).
- Keep copy factual and calm; no hype.

## Forbidden Moves

- No trackers or surprise cookies.
- No unbounded JS additions outside the existing site/runtime model.
- No stale tunnel-only or static-only claims when the selected runtime mode needs the Axum server path.
