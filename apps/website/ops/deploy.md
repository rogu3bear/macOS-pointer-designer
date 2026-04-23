# Deploy to Cloudflare Pages

1. **Connect Repository**: Link your GitHub repo to Cloudflare Pages.
2. **Build Configuration**:
   - **Framework Preset**: None (Manual)
   - **Build Command**: `cd apps/website/site && ./scripts/build-release.sh`
   - **Build Output Directory**: `apps/website/site/dist`
3. **Environment Variables**: None required.
4. **Dependency Installation**: Cloudflare pages usually detects Rust, but if not, ensure `trunk` is installed or use a build script.

*Note: Since this is a SPA, ensure Cloudflare Pages redirects 404s to `index.html` (Default behavior for single page apps usually needs verification).*
