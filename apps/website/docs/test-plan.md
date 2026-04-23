# Test Plan

## Automated Checks

Run from `drop-web root`: `./ops/verify.sh`

Or manually in `site/`:
1. **Compilation**: `cargo check`
2. **Server compilation**: `cargo check --features ssr --bin windowdrop-server`
3. **Formatting**: `cargo fmt -- --check`
4. **Clippy**: `cargo clippy -- -D warnings`
5. **Server clippy**: `cargo clippy --features ssr --bin windowdrop-server -- -D warnings`
6. **Tests**: `cargo test --features ssr`
7. **Build**: `trunk build --release`

## Manual Verification
1. **Navigation**: Click all header/footer links. Verify URL changes and content updates without reload.
2. **Responsiveness**: Resize window. Verify nav stacks on mobile (<768px). Test at 320px, 768px, 1920px, and 4K (3840px) viewports.
3. **SEO (CSR)**: Do not use "View Source" for meta tags (CSR will show the static `index.html`). Instead:
   - Open DevTools → Elements and check `<head>` for `<title>`, `<meta name="description">`, canonical links, and OG/Twitter tags after navigation.
   - (Optional) Run Lighthouse or use a crawler that executes JS if you need to validate share previews.
4. **Assets**: Verify Logo and Favicon load.
5. **Routes**:
   - `/`: Check Hero, "How it works", and "Works with" (Finder, Safari, Terminal, Mail, Chrome/Firefox/Xcode & more).
   - `/download`: In pre-launch mode: email capture, "When Released" section; in release mode: download links, Alternative Downloads, Verify. Check requirements and installation steps.
   - `/pricing`: Check free Finder (`$0`) and lifetime unlock (`$7.99 one-time`) cards, free CTA ("Download Free"), and lifetime CTA:
     - Default/release-safe mode: CTA is "Buy Lifetime in App" to `/download`.
     - Web checkout mode: CTA is "Buy Lifetime" to `/checkout/lifetime` only when `SITE_LIFETIME_MODE=web` and the live Pages proxy is verified healthy.
   - `/checkout/success`: In web mode, verify successful purchase messaging, activation link/code, and recovery guidance.
   - `/checkout/recover`: In web mode, verify email-based recovery flow and activation code rendering.
   - `/privacy`: Check promise cards and bullets.
   - `/support`: Check FAQ, troubleshooting (current placement modes: Cursor + Close Button, Titlebar Grab Zone), and supported-apps text.
   - `/changelog`: Check the "Current" entry matches `WINDOWDROP_RELEASE_VERSION` / the downloadable DMG version, verify the release notes mention download + activation truthfully, and confirm historical entries still cover placement modes, app coverage (browsers, terminals, mail, IDEs), and the Stay Updated CTA.
   - `/404`: Visit a random URL to verify Not Found page.
