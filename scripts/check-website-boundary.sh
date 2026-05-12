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

if ! grep -Fq "There is no canonical Cursor Designer website in this repository yet." README.md; then
  echo "ERROR: README.md must preserve the no-canonical-website boundary." >&2
  exit 1
fi

if ! grep -Fq "A public website must not exist until" NORTH_STAR.md; then
  echo "ERROR: NORTH_STAR.md must preserve the no-canonical-website boundary." >&2
  exit 1
fi

echo "Cursor Designer website boundary check passed."
