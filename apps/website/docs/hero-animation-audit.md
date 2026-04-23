# Hero Animation Audit

**Component**: `HeroAnimation` (WindowDrop demonstration graphic)  
**Files**: `site/src/components/hero_animation.rs`, `site/styles/components.css`  
**Date**: 2026-02-25

---

## Overview

The hero animation is an SVG-based demo that shows the difference between default macOS Cmd+N behavior (windows stack) and WindowDrop behavior (window appears under cursor). It runs as a 7-second choreographed sequence or displays a static fallback.

---

## How It Functions

### 1. Entry Point and Modes

| Mode | Trigger | Output |
|------|---------|--------|
| **Animated** | `CONFIG.animation_enabled && !prefers-reduced-motion` | 7s CSS animation sequence |
| **Static** | `prefers-reduced-motion` or `!animation_enabled` | Single-frame SVG showing final state |

- **Config**: `config.rs` → `animation_enabled: true`
- **Reduced motion**: `window.match_media("(prefers-reduced-motion: reduce)")` checked at render
- **Analytics**: `AnimationViewed` fired after 7s when animated

### 2. Structure

```
HeroAnimation (role="img", aria-label)
├── hero-animation-stage (aspect-ratio 16/9, gradient bg)
│   ├── AnimatedDemo (SVG 900×520) OR StaticDemo (SVG 900×520)
│   └── ::before (ambient pulse animation)
└── hero-animation-caption (text + <kbd>⌘N</kbd>)
```

### 3. Animated Sequence (7 seconds)

| Time | Phase | Elements |
|------|-------|----------|
| 0–14% (0–1s) | Setup | Cursor at start (72vw, 24vh); existing Finder visible |
| 14–20% | First Cmd+N | `hero-keys-default` fades in |
| 20–30% | Default window appears | `hero-window-default` animates in near Finder |
| 30–42% | Hold | Default window visible; `hero-mode-default` label shown |
| 42–58% | Cursor moves | Cursor translates to (76vw, 38vh) |
| 52–62% | Toggle transition | `windowdrop-toggle-off` fades out |
| 58–66% | WindowDrop armed | `windowdrop-toggle-on` fades in |
| 62–68% | Second Cmd+N | `hero-keys-windowdrop` fades in |
| 68–76% | WindowDrop window | `hero-window-windowdrop` animates in under cursor |
| 76–84% | Highlight | `cursor-highlight` circle pulses |
| 66–100% | Final state | `hero-mode-windowdrop` label; default window at 0.35 opacity |

### 4. SVG Elements (AnimatedDemo)

| Class | Purpose |
|-------|---------|
| `existing-window` | Original Finder window (always visible) |
| `hero-window-default` | New window from first Cmd+N (stacks, then fades to 0.35) |
| `hero-window-windowdrop` | New window from second Cmd+N (under cursor) |
| `hero-cursor` | Mouse cursor path |
| `hero-keys-default` | First ⌘N keycap |
| `hero-keys-windowdrop` | Second ⌘N keycap |
| `hero-mode-default` | "Default Cmd+N: stacks near existing Finder window" |
| `hero-mode-windowdrop` | "WindowDrop: new window appears under cursor" |
| `windowdrop-toggle-off` | Menu bar "WindowDrop Off" |
| `windowdrop-toggle-on` | Menu bar "WindowDrop Active" |
| `cursor-highlight` | Dashed circle at cursor target |

### 5. Positioning (Viewport-Relative)

Animations use `min(702px, 76vw)` and `min(278px, 38vh)` so the cursor and target scale with viewport. On narrow viewports, `76vw` can push the cursor off the right edge.

### 6. Static Fallback

- Uses separate SVG (`StaticDemo`) with `-static` suffix on def IDs to avoid conflicts
- Shows: existing window, ghosted default window (0.35), cursor at target, WindowDrop window, green label
- No keycaps, no toggle transition

---

## Issues and Gaps

### A. Responsiveness

| Issue | Severity | Detail |
|-------|----------|--------|
| Fixed viewBox | Medium | SVG is 900×520; scales via `width:100%` but internal coordinates are px-based |
| Cursor overflow | Medium | `min(702px, 76vw)` — on ~920px viewport, 76vw=700px; below that cursor can clip or misalign |
| Label overflow | Low | "Default Cmd+N: stacks near existing Finder window" may wrap on mobile |
| Keycap position | Low | ⌘N keycaps at x=620 and x=672 are fixed; may overlap or look odd when scaled |

### B. Animation Choreography

| Issue | Severity | Detail |
|-------|----------|--------|
| No loop | Low | Plays once; no replay or pause control |
| Toggle opacity | Low | `windowdrop-toggle-on` ends at 0.6, not 1; may look dim |
| Timing overlap | Low | Several animations share keyframe ranges; minor overlap at transitions |
| Cursor path | Low | Linear move; could add slight ease for more natural feel |

### C. Accessibility

| Issue | Severity | Detail |
|-------|----------|--------|
| role="img" | OK | Decorative/animated graphic correctly marked |
| aria-label | OK | Describes both default and WindowDrop behavior |
| No pause | Medium | No way to pause for users who need more time |
| Caption | OK | Text caption reinforces the message |

### D. Code Quality

| Issue | Severity | Detail |
|-------|----------|--------|
| Duplicate SVG | Medium | AnimatedDemo and StaticDemo duplicate ~80% of markup |
| Magic numbers | Low | 702, 278, 654, 148, etc. scattered in keyframes |
| ID collisions | Mitigated | Static uses `-static` suffix on pattern/gradient IDs |

### E. Visual / UX

| Issue | Severity | Detail |
|-------|----------|--------|
| Stage ambient | Low | `stageAmbient` (15s) runs during 7s demo; can feel disconnected |
| Cursor highlight | Low | `highlightPulse` fades out by 100%; might be clearer if it lingered |
| Text contrast | OK | Labels use dark/light fills; readable |

---

## Recommendations (Prioritized)

1. ~~**Add replay control**~~ — **Done.** Replay button added; remounts AnimatedDemo on click.
2. ~~**Fix viewport overflow**~~ — **Done.** Cursor uses `clamp()` to stay in bounds on narrow viewports.
3. **Extract shared SVG** — Deferred. AnimatedDemo and StaticDemo still duplicate markup.
4. ~~**Set toggle-on opacity to 1**~~ — **Done.** `toggleOnAppear` 100% keyframe now 1.
5. ~~**Static on narrow viewports**~~ — **Done.** `@media (max-width: 640px)` forces final frame; replay hidden.
6. **Document keyframe timeline** — Deferred.

---

## Verification

```bash
cd apps/website/site && trunk serve
# Visit http://127.0.0.1:3411
# 1. Watch full 7s animation
# 2. Enable "Reduce motion" in OS; reload — should see static
# 3. Resize to 400px width — check cursor/label clipping
# 4. Resize to 4K — check scaling
```
