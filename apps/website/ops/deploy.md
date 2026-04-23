# Deployment

## Canonical: Cloudflare Pages (`SITE_LIFETIME_MODE=in-app`)

Production serves the public marketing, pricing, changelog, support, and download site from the Cloudflare Pages project `windowdrop`.

1. Confirm the latest public release in `ops/release-env.sh`.
2. Build and deploy through the Cloudflare control plane:

   ```bash
   ./ops/deploy-pages.sh
   ```

3. Ensure `windowdrop.pro` and `www.windowdrop.pro` are attached as Pages custom domains.
4. Verify:
   - `curl -I https://windowdrop.pro`
   - `curl -I https://windowdrop.pro/download`
   - `curl -I https://windowdrop.pro/pricing`

The current public release assets are hosted on GitHub Releases in `rogu3bear/windowdrop`:
- DMG: `WindowDrop-1.0.1.dmg`
- ZIP: `WindowDrop-1.0.1.zip`
- Checksums: `WindowDrop-1.0.1-checksums.txt`

## Optional: Axum Web Checkout Runtime

Use the Axum runtime only when intentionally enabling website checkout with `SITE_LIFETIME_MODE=web`. It owns:
- `GET /checkout/lifetime`
- `GET /api/web-license/session`
- `POST /api/web-license/activate`
- `POST /api/web-license/recover`

Runtime environment (see `.env.example` for all vars):
   - `SITE_LIFETIME_MODE=web` to route the pricing CTA to `/checkout/lifetime`
   - `STRIPE_API_KEY` for server-side Stripe Checkout session creation and Stripe purchase lookup
   - `WINDOWDROP_WEB_LICENSE_PRIVATE_KEY_PATH` for signing the activation token returned by `/api/web-license/*`
   - `WINDOWDROP_SITE_URL` (optional) to override the default `https://windowdrop.pro` redirect base
   - `RESEND_API_KEY` + `RESEND_FROM_EMAIL` for license email delivery via Resend

Smoke test:
   - `curl -I http://127.0.0.1:3410/checkout/lifetime`
   - With runtime secrets configured: expect `302 Found` redirecting to Stripe Checkout
   - Without runtime secrets: expect `503 Service Unavailable` JSON explaining which checkout env is missing

Do not switch the public Pages build to `SITE_LIFETIME_MODE=web` until the custom-domain proxy is verified live for checkout and recovery.
