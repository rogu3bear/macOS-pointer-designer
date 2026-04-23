# In-App Lifetime Unlock Setup for WindowDrop ($7.99)

WindowDrop unlocks paid features as a one-time lifetime purchase (`$7.99`).

The website pricing page should direct users to:
- Download the app for free (Finder support)
- Buy lifetime for `$7.99` through the app/download flow by default
- Optionally switch to the server-backed Stripe + web-license flow when `SITE_LIFETIME_MODE=web` only after the live Pages proxy has been verified

## App Store Connect Setup

1. Open App Store Connect for WindowDrop.
2. Create a **Non-Consumable** in-app purchase.
3. Set product ID to:
   - `com.windowdrop.lifetime.unlock`
4. Set price to `$7.99` (USD tier equivalent).
5. Submit metadata/screenshot for review.

## Website Setup

The pricing page should:
- Show free + lifetime tiers
- Always route the free card to the free app download
- Route lifetime CTA based on config:
  - `SITE_LIFETIME_MODE=in-app` (default): "Buy Lifetime in App" to `/download`
  - `SITE_LIFETIME_MODE=web`: "Buy Lifetime" to `/checkout/lifetime`, which creates a Stripe Checkout session server-side

## Optional App Store Link

If you want a store listing link on the site, set:

```bash
APP_STORE_URL="https://apps.apple.com/app/windowdrop/idYOUR_APP_ID" trunk build --release
```

## Optional Web Checkout Mode

Web checkout is now a real fulfillment path, not a raw Stripe payment link. It requires:

```bash
SITE_LIFETIME_MODE=web
STRIPE_API_KEY=sk_live_...
WINDOWDROP_WEB_LICENSE_PRIVATE_KEY_PATH=/absolute/path/to/windowdrop-web-license-private-key.pem
WINDOWDROP_SITE_URL=https://windowdrop.pro   # optional override
```

The app must also ship the matching public key in `WindowDropWebLicensePublicKeyX963Base64`.

Keep the public site in `SITE_LIFETIME_MODE=in-app` until:
- `https://windowdrop.pro/checkout/lifetime` redirects to Stripe from the custom domain
- `POST https://windowdrop.pro/api/web-license/recover` reaches the intended backend instead of a Cloudflare origin error
- the backing activation registry is shared and persistent across server instances

## Verification

1. Open `/pricing` and confirm:
   - Free card CTA is "Download Free"
   - Lifetime card CTA is "Buy Lifetime in App" when `SITE_LIFETIME_MODE=in-app`
   - Lifetime card CTA is "Buy Lifetime" only when `SITE_LIFETIME_MODE=web`
2. Click lifetime CTA and verify it routes to the configured destination.
3. In app, open Preferences → Access:
   - "Unlock In App ($7.99)" starts StoreKit purchase flow
   - "Restore Purchases" restores a prior entitlement
4. In web mode, verify:
   - `/checkout/lifetime` redirects to Stripe Checkout
   - `/checkout/success?session_id=...` returns a signed activation link/code after a completed payment
   - `/checkout/recover` can recover the purchase by checkout email
