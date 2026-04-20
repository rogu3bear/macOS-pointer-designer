# Test Plan

## Automated Checks
1. **Compilation**: `cargo check` in `site/` directory.
2. **Formatting**: `cargo fmt -- --check`.
3. **Clippy**: `cargo clippy -- -D warnings`.
4. **Build**: `trunk build --release`.

## Manual Verification
1. **Navigation**: Click all header/footer links. Verify URL changes and content updates without reload.
2. **Responsiveness**: Resize window. Verify nav stacks on mobile (<640px).
3. **SEO (CSR)**: Do not use "View Source" for meta tags (CSR will show the static `index.html`). Instead:
   - Open DevTools → Elements and check `<head>` for `<title>`, `<meta name="description">`, canonical links, and OG/Twitter tags after navigation.
   - (Optional) Run Lighthouse or use a crawler that executes JS if you need to validate share previews.
4. **Assets**: Verify Logo and Favicon load.
5. **Routes**:
   - `/`: Check Hero and "How it works".
   - `/download`: Check table.
   - `/privacy`: Check bullets.
   - `/support`: Check FAQ rendering.
   - `/changelog`: Check markdown content.
   - `/404`: Visit a random URL to verify Not Found page.
