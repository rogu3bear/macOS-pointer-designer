#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "$0")/.." && pwd)"
cd "$ROOT_DIR"

if [[ -d "apps/website" ]]; then
  echo "ERROR: apps/website exists, but No canonical Cursor Designer website exists yet." >&2
  echo "A website is blocked until the app has a verified release source, domain, download path, and compatibility story." >&2
  echo "See NORTH_STAR.md and apps/macos/RELEASE_RUNBOOK.md." >&2
  exit 1
fi

website_scaffold=$(
  find . \
    -path './.git' -prune -o \
    -path './apps/macos/.build' -prune -o \
    -path './apps/macos/Sources' -prune -o \
    -path './apps/macos/Tests' -prune -o \
    -type f \( \
      -name 'wrangler.toml' -o \
      -name 'leptos.toml' -o \
      -name 'package.json' -o \
      -name 'vite.config.*' -o \
      -name 'index.html' -o \
      -name 'worker.*' \
    \) -print
)

if [[ -n "$website_scaffold" ]]; then
  printf '%s\n' "$website_scaffold" >&2
  echo "ERROR: website or Cloudflare/Leptos scaffold exists before a verified release source and domain." >&2
  echo "Use the Leptos Cloudflare template only after NORTH_STAR.md website prerequisites are satisfied." >&2
  exit 1
fi

if ! grep -Fq "There is no canonical Cursor Designer website in this repository yet." README.md; then
  echo "ERROR: README.md must preserve the no-canonical-website boundary." >&2
  exit 1
fi

if ! grep -Fq "Do not scaffold a generic SaaS site" README.md; then
  echo "ERROR: README.md must block generic website scaffolding." >&2
  exit 1
fi

if ! grep -Fq "technical base only" README.md; then
  echo "ERROR: README.md must keep the Leptos Cloudflare template as a technical base only." >&2
  exit 1
fi

if ! grep -Fq "privacy-preserving download routing" README.md; then
  echo "ERROR: README.md must constrain future template capabilities to truthful release delivery." >&2
  exit 1
fi

if ! grep -Fq "add accounts, dashboards, analytics" README.md; then
  echo "ERROR: README.md must reject unnecessary website product sprawl." >&2
  exit 1
fi

if ! grep -Fq "A public website must not exist until" NORTH_STAR.md; then
  echo "ERROR: NORTH_STAR.md must preserve the no-canonical-website boundary." >&2
  exit 1
fi

if ! grep -Fq "Use the operator's Leptos Cloudflare template only as the technical base" NORTH_STAR.md; then
  echo "ERROR: NORTH_STAR.md must preserve the Leptos Cloudflare template boundary." >&2
  exit 1
fi

if ! grep -Fq "release metadata reads, digest display" NORTH_STAR.md; then
  echo "ERROR: NORTH_STAR.md must name the allowed release-truth template capabilities." >&2
  exit 1
fi

if ! grep -Fq "Do not add accounts, dashboards, analytics" NORTH_STAR.md; then
  echo "ERROR: NORTH_STAR.md must reject unnecessary website product sprawl." >&2
  exit 1
fi

if ! grep -Fq "Avoid stock-layout filler" NORTH_STAR.md; then
  echo "ERROR: NORTH_STAR.md must preserve the anti-placeholder website standard." >&2
  exit 1
fi

if ! grep -Fq "no fake testimonials" NORTH_STAR.md; then
  echo "ERROR: NORTH_STAR.md must reject fake website proof and filler." >&2
  exit 1
fi

echo "Cursor Designer website boundary check passed."
