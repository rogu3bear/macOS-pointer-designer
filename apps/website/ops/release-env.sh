#!/usr/bin/env bash
# Canonical public release metadata for the website build/deploy surfaces.
# Source this file before building the static site or SSR server.

export WINDOWDROP_RELEASE_REPO="${WINDOWDROP_RELEASE_REPO:-rogu3bear/windowdrop}"
export WINDOWDROP_RELEASE_VERSION="${WINDOWDROP_RELEASE_VERSION:-1.0.1}"
export WINDOWDROP_RELEASE_TAG="${WINDOWDROP_RELEASE_TAG:-v${WINDOWDROP_RELEASE_VERSION}}"
export WINDOWDROP_RELEASE_URL="${WINDOWDROP_RELEASE_URL:-https://github.com/${WINDOWDROP_RELEASE_REPO}/releases/tag/${WINDOWDROP_RELEASE_TAG}}"
export WINDOWDROP_DMG_URL="${WINDOWDROP_DMG_URL:-https://github.com/${WINDOWDROP_RELEASE_REPO}/releases/download/${WINDOWDROP_RELEASE_TAG}/WindowDrop-${WINDOWDROP_RELEASE_VERSION}.dmg}"
export WINDOWDROP_ZIP_URL="${WINDOWDROP_ZIP_URL:-https://github.com/${WINDOWDROP_RELEASE_REPO}/releases/download/${WINDOWDROP_RELEASE_TAG}/WindowDrop-${WINDOWDROP_RELEASE_VERSION}.zip}"
export WINDOWDROP_CHECKSUMS_URL="${WINDOWDROP_CHECKSUMS_URL:-https://github.com/${WINDOWDROP_RELEASE_REPO}/releases/download/${WINDOWDROP_RELEASE_TAG}/WindowDrop-${WINDOWDROP_RELEASE_VERSION}-checksums.txt}"

# Production Pages is static/in-app by default. Switch to web only after the
# checkout origin and Pages proxy are verified live.
export SITE_LIFETIME_MODE="${SITE_LIFETIME_MODE:-in-app}"
