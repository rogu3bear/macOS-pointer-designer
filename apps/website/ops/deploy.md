# Deployment

## Primary: Axum + Cloudflare Tunnel

Production uses the Axum static file server on port 3410, behind Caddy, exposed via Cloudflare Tunnel.

1. Build: `cd site && ./scripts/build-release.sh`
2. Runtime environment (see `.env.example` for all vars):
   - `SITE_LIFETIME_MODE=web` to route the pricing CTA to `/checkout/lifetime`
   - `STRIPE_API_KEY` for server-side Stripe Checkout session creation and Stripe purchase lookup
   - `WINDOWDROP_WEB_LICENSE_PRIVATE_KEY_PATH` for signing the activation token returned by `/api/web-license/*`
   - `WINDOWDROP_SITE_URL` (optional) to override the default `https://windowdrop.pro` redirect base
   - `RESEND_API_KEY` + `RESEND_FROM_EMAIL` for license email delivery via Resend
   - `WINDOWDROP_DMG_URL` (optional) to override the default versioned `/downloads/WindowDrop-<version>.dmg` link
3. Run: `PORT=3410 ./target/release/windowdrop-server` (or via launchd / Docker)
4. Health: `curl http://127.0.0.1:3410/healthz`
5. Smoke test:
   - `curl -I http://127.0.0.1:3410/checkout/lifetime`
   - With runtime secrets configured: expect `302 Found` redirecting to Stripe Checkout
   - Without runtime secrets: expect `503 Service Unavailable` JSON explaining which checkout env is missing

See `README.md` and `Dockerfile` for Docker and launchd setup.

This runtime is required when `SITE_LIFETIME_MODE=web`, because the Rust server owns:
- `GET /checkout/lifetime`
- `GET /api/web-license/session`
- `POST /api/web-license/activate`
- `POST /api/web-license/recover`

## Alternative: Cloudflare Pages (`SITE_LIFETIME_MODE=in-app`)

For the marketing site, waitlist capture, and app downloads without the Axum runtime:

1. Run the root deploy script: `./ops/deploy-pages.sh`
2. Ensure the Cloudflare Pages project `windowdrop` has these production secrets:
   - `RESEND_API_KEY`
   - `RESEND_AUDIENCE_ID`
   - optional: `NOTIFY_EMAIL`, `TURNSTILE_SECRET`
3. Ensure `windowdrop.pro` and `www.windowdrop.pro` are attached as Pages custom domains.
4. Verify:
   - `curl -I https://windowdrop.pro`
   - `curl -sS -X POST https://windowdrop.pro/api/subscribe -H 'Origin: https://windowdrop.pro' -H 'Content-Type: application/json' --data '{"email":"invalid"}'`

The repo-backed Pages Function lives at [`functions/api/subscribe.js`](/Users/star/Dev/windowdrop/functions/api/subscribe.js). Pages hosting covers the email capture flow, but the Stripe checkout redirect, session verification, activation exchange, and purchase recovery still require the Axum runtime above.
