# Reconciliation: drop-web vs WindowDrop Codebase & Best Practices

This document reconciles the drop-web site with the parent WindowDrop codebase and documents best practices for consistency.

---

## 1. Supported Apps (Content Accuracy)

**Source of truth**: `packages/windowdrop-core/Sources/WindowDropCore/SettingsModel.swift` — `appTargets` and `AppTargetCategory`.

**App reality**: Category-driven allowlist:
- **Core**: Finder
- **Browsers**: Safari, Chrome, Firefox, Edge, Brave, Arc
- **Terminals**: Terminal, iTerm2, Warp, WezTerm, Alacritty, Kitty
- **Mail**: Apple Mail, Outlook, Spark, Mimestream
- **IDEs**: Xcode, VS Code, Cursor, IntelliJ, PyCharm, WebStorm, CLion, GoLand, Rider, Android Studio

**Website was wrong**: Listed Finder, Safari, Preview, TextEdit, Notes, Mail (Soon). Preview, TextEdit, and Notes are **not** in `SettingsModel.appTargets`. Mail is supported; Chrome, Firefox, Terminal, Xcode, etc. are supported.

**Reconciliation**: Update "Works with" and Support FAQ/troubleshooting to show representative apps from actual categories: Finder, Safari, Terminal, Mail, and "Chrome, Firefox, Xcode & more" (or similar). Remove Preview, TextEdit, Notes. Mark Mail as supported, not "Soon".

---

## 2. Placement Mode Names

**Source of truth**: `packages/windowdrop-core/Sources/WindowDropCore/PlacementMode.swift` — `rawValue` (display name).

| Enum case | App display name |
|----------|------------------|
| `cursorCloseButton` | "Cursor + Close Button" |
| `screenCenter` | "Screen Center" |
| `titlebarGrabZone` | "Titlebar Grab Zone" |

**Website had**: "Cursor", "Screen Center", "Title Bar" (Support troubleshooting).

**Reconciliation**: Use app display names in Support troubleshooting so users can match settings UI: "Cursor + Close Button", "Screen Center", "Titlebar Grab Zone". Note: Screen Center is deprecated in app UI (hidden from picker) but still valid in code.

---

## 3. macOS Version

**Source of truth**: `packages/windowdrop-core/Package.swift` (`.macOS(.v13)`), `app/WindowDrop.xcodeproj/project.pbxproj` (`MACOSX_DEPLOYMENT_TARGET = 13.0`).

**Reconciliation**: Website correctly states "Ventura 13.0 or later". No change.

---

## 4. Card Patterns (Best Practice)

**Current card types** (by page):

| Page | Card class | Purpose |
|------|------------|---------|
| Home | `value-card` | Value props (Why WindowDrop?) |
| Home | `step` | How it works (numbered) |
| Home | `app-card` | Supported apps |
| Download | `requirement-card` | System requirements |
| Download | `install-step` | Installation steps |
| Download | `alternative-card` | DMG/ZIP options |
| Download | `verify-card` | SHA-256 verification |
| Privacy | `promise-card` | Privacy promises |
| Support | `quick-link-card` | Quick help links |

**Best practice** (per drop-web AGENTS.md, content-style.md):
- One responsibility per component
- Semantic HTML, logical heading hierarchy
- Generous whitespace, max-width enforced
- No marketing fluff; short, factual copy

**Recommendation**: No structural refactor. For future additions:
- Use existing card classes where semantically appropriate
- Prefer `*-card` suffix for card-like blocks
- Keep step-based flows as `step` or `*-step` for consistency

---

## 5. FAQ Consistency

**Two FAQ sources**:
1. **Home** (`FaqSection`): Hardcoded in `faq_section.rs` — 4 items
2. **Support** (`faq.md`): Markdown in `content/faq.md` — 4 items (different content)

**Overlap**: Both ask "Which apps?" and "Does WindowDrop read data?". Answers differed.

**Reconciliation**: Align FAQ answers with app reality. Support page uses `faq.md`; Home uses `FaqSection`. Keep both but ensure consistent facts (supported apps, placement modes, permissions).

---

## 6. Parent Repo Alignment

**CLAUDE.md** (root): Says "Allowlist-based (currently Finder + Safari)". **Outdated** — app supports 20+ apps across 5 categories.

**docs/architecture.md** (root): Correctly states "category-driven through a shared app-target catalog: core (Finder), browsers, terminals, mail, and IDEs".

**Reconciliation**: Root CLAUDE.md is outside drop-web scope. Document in this file for future parent-repo updates.

---

## 7. Forbidden Moves (Reminder)

Per parent AGENTS.md and drop-web AGENTS.md:
- No telemetry, trackers, or analytics beyond console logging
- No backend services, databases, or APIs
- No modifications to macOS app from drop-web
- No "refactor for taste" — only factual alignment

---

## Summary of Edits Applied

1. **Home** (`home.rs`): Replace Preview, TextEdit, Notes, Mail (Soon) with Finder, Safari, Terminal, Mail, Chrome (or "& more") to match `SettingsModel`.
2. **FaqSection** (`faq_section.rs`): Update "Which apps?" answer to match app categories.
3. **Support** (`support.rs`): Update placement mode names; update "supported apps" list in troubleshooting.
4. **faq.md**: Update "Which apps are supported?" to match `SettingsModel`.
5. **docs/architecture.md** (drop-web): Add reconciliation reference.
6. **docs/test-plan.md** (drop-web): Ensure manual checks cover updated content.
