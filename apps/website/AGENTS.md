# AGENTS.md (Website)

This repository contains the **WindowDrop website only**.
It is a static Leptos site built with Rust and Trunk.

Agents are used to accelerate implementation while preserving clarity,
determinism, and deployability.

---

## Scope boundaries (hard)
Agents working in this repo MUST NOT:
- Modify the macOS app code.
- Modify Cloudflare DNS, Workers, or Pages settings directly.
- Modify Google Workspace or email configuration.
- Introduce backend services, databases, or APIs.
- Introduce analytics or trackers without explicit instruction.

This repo is **content + presentation only**.

---

## Tech stack (locked)
- Language: Rust
- Framework: Leptos (CSR)
- Build tool: Trunk
- Styling: plain CSS (no Tailwind, no CSS-in-JS)
- Markdown: pulldown-cmark
- Hosting: static output (Cloudflare Pages or equivalent)

No deviations unless explicitly approved.

---

## Repo layout (expected)
- `site/`        Leptos application
- `site/src/`    Rust source
- `site/styles/` CSS only
- `site/assets/` Images, SVGs, favicon, OG assets
- `site/public/` robots.txt, sitemap.xml
- `docs/`        Architecture, test plan, content guidelines
- `ops/`         Deployment and analytics notes (documentation only)

Agents must respect this structure.

---

## Output contract (required for every agent)
Every agent response MUST include:

1) **Summary**
- What was added or changed.
- Why it was necessary.

2) **Files touched**
- Explicit list of file paths (relative).
- No implicit edits.

3) **Full contents or patch**
- New files: full contents.
- Existing files: unified diff preferred.

4) **Verification**
- Exact commands to run (`trunk serve`, `trunk build --release`, etc.).
- Expected behavior in browser.

If something cannot be verified locally, state why.

---

## Content rules
- Copy must be short, factual, and calm.
- No hype. No metaphors. No marketing fluff.
- Line length should remain readable.
- Accessibility and clarity beat cleverness.

When adding new content pages:
- Add them to routing.
- Add them to sitemap.xml.
- Add them to navigation if user-facing.

---

## Design rules
- Single accent color.
- System font stack only.
- Generous whitespace.
- Maximum content width enforced.
- Mobile-first, but desktop-readable.

Agents must not “redesign” pages unless explicitly asked.

---

## SEO and metadata
- Every route must define:
  - `<title>`
  - meta description
  - canonical URL
  - OpenGraph tags
- Canonical domain is `https://windowdrop.pro`.
- No SEO experiments. Just correctness.

---

## Performance rules
- Avoid heavy dependencies.
- Avoid large images.
- Avoid unused CSS.
- Static output should be small and fast.

If bundle size increases meaningfully, explain why.

---

## Accessibility expectations
- Semantic HTML elements.
- Logical heading hierarchy.
- Visible focus states.
- Keyboard navigation must work.
- Color contrast must be sane.

Accessibility is not optional.

---

## Wave discipline
- Work is done in **waves**.
- Wave 1: scaffolding, routing, content, structure.
- Wave 2: polish, correctness, performance, accessibility.

Agents must not depend on unmerged changes from the same wave.

---

## Documentation duties
If you add or change behavior, update:
- `docs/architecture.md`
- `docs/test-plan.md`
- `docs/content-style.md` (if copy rules change)

Docs are part of the deliverable.

---

## Forbidden moves
- Adding telemetry or trackers.
- Adding cookies without disclosure.
- Adding JavaScript outside Leptos.
- Adding “temporary” hacks without notes.
- Leaving TODOs without context.

---

## Agent sizing
Tasks should be **moderate**:
- One agent, one clear responsibility.
- If a task grows, split it.
- Avoid “mega” changesets.

---

## Definition of done
An agent task is done when:
- `trunk serve` works.
- `trunk build --release` succeeds.
- Pages render correctly when loaded directly by URL.
- Docs reflect the change.
- No dead code remains.

---

## Default agent response template

Use this template exactly:

### Summary
- …

### Files touched
- …

### Patch / Contents
- …

### Verification
- Command:
  - …
- Expected:
  - …

## Inventory & Findings (2026-02-03)
- Hosting/Deployment: Cloudflare Tunnel via unified ingress; Axum server on port 3410 behind Caddy.
- Key Configs Present: `site/Trunk.toml`, `site/Cargo.toml`, `site/src/bin/server.rs`.
- Rectifications Made: Archived this mirror; canonical service path in registry is `drop-web/site`.
- External Follow-ups: None.

## Inventory & Findings (2026-02-03)
- Hosting/Deployment: Cloudflare Tunnel via unified ingress; Axum server on port 3410 behind Caddy.
- Key Configs Present: `site/Trunk.toml`, `site/Cargo.toml`, `site/src/bin/server.rs`.
- Rectifications Made: Default server port corrected to 3410 to match registry and ops health checks.
- External Follow-ups: None. Duplicate `windowdrop-web/` mirror archived to `_archive/windowdrop-web.mirror/`.
