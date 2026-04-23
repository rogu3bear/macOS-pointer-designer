#!/usr/bin/env bash
# Create Stripe pricing artifacts for WindowDrop:
# - Lifetime one-time unlock: $7.99
#
# Run from drop-web root: ./ops/stripe-setup.sh
#
# Prerequisites:
# - stripe CLI authenticated (stripe login) or STRIPE_API_KEY env
# - jq installed
# Optional:
# - ARCHIVE_MONTHLY=1 (default) to disable existing monthly recurring prices on the product

set -euo pipefail

REDIRECT_BASE="${AFTER_PAYMENT_URL:-https://windowdrop.pro/download}"
LIVE="${LIVE:-}"
PRODUCT_NAME="${PRODUCT_NAME:-WindowDrop}"
PRODUCT_DESCRIPTION="${PRODUCT_DESCRIPTION:-macOS menu bar utility that moves new windows to the screen where your cursor is.}"
LIFETIME_AMOUNT_CENTS="${LIFETIME_AMOUNT_CENTS:-799}"
PRODUCT_ID="${PRODUCT_ID:-}"
ARCHIVE_MONTHLY="${ARCHIVE_MONTHLY:-1}"
EXPECTED_STRIPE_ACCOUNT_ID="${EXPECTED_STRIPE_ACCOUNT_ID:-}"

if ! command -v stripe >/dev/null 2>&1; then
  echo "stripe CLI not found. Install from https://stripe.com/docs/stripe-cli"
  exit 1
fi

if ! command -v jq >/dev/null 2>&1; then
  echo "jq is required. Install jq and retry."
  exit 1
fi

MODE_ARGS=()
if [[ -n "$LIVE" ]]; then
  MODE_ARGS+=(--live)
fi

stripe_json() {
  local output
  if [[ ${#MODE_ARGS[@]} -gt 0 ]]; then
    output="$(stripe "$@" "${MODE_ARGS[@]}")"
  else
    output="$(stripe "$@")"
  fi

  if echo "$output" | jq -e '.error != null' >/dev/null 2>&1; then
    local err_msg err_type req_log_url
    err_msg="$(echo "$output" | jq -r '.error.message // "Unknown Stripe API error"')"
    err_type="$(echo "$output" | jq -r '.error.type // "unknown_error"')"
    req_log_url="$(echo "$output" | jq -r '.error.request_log_url // empty')"
    echo "ERROR: Stripe API call failed (${err_type}): ${err_msg}" >&2
    if [[ -n "$req_log_url" ]]; then
      echo "Request log: $req_log_url" >&2
    fi
    return 1
  fi

  printf '%s\n' "$output"
}

require_nonempty_id() {
  local value="$1"
  local label="$2"
  if [[ -z "$value" || "$value" == "null" ]]; then
    echo "ERROR: Missing ${label} from Stripe response." >&2
    exit 1
  fi
}

append_plan_query() {
  local base="$1"
  local plan="$2"
  if [[ "$base" == *\?* ]]; then
    printf "%s&purchased=%s" "$base" "$plan"
  else
    printf "%s?purchased=%s" "$base" "$plan"
  fi
}

ACCOUNT_JSON="$(stripe_json accounts retrieve)"
ACCOUNT_ID="$(echo "$ACCOUNT_JSON" | jq -r '.id')"
ACCOUNT_NAME="$(echo "$ACCOUNT_JSON" | jq -r '.business_profile.name // .company.name // "Unknown"')"
ACCOUNT_EMAIL="$(echo "$ACCOUNT_JSON" | jq -r '.email // "Unknown"')"
CHARGES_ENABLED="$(echo "$ACCOUNT_JSON" | jq -r '.charges_enabled')"
require_nonempty_id "$ACCOUNT_ID" "account id"

echo "Using Stripe account: ${ACCOUNT_ID} (${ACCOUNT_NAME}, ${ACCOUNT_EMAIL})"
if [[ -n "$EXPECTED_STRIPE_ACCOUNT_ID" && "$ACCOUNT_ID" != "$EXPECTED_STRIPE_ACCOUNT_ID" ]]; then
  echo "ERROR: Stripe account mismatch." >&2
  echo "Expected: $EXPECTED_STRIPE_ACCOUNT_ID" >&2
  echo "Actual:   $ACCOUNT_ID" >&2
  echo "Refusing to continue." >&2
  exit 1
fi

if [[ -n "$LIVE" && "$CHARGES_ENABLED" != "true" ]]; then
  echo "ERROR: Live mode requested but account charges are not enabled." >&2
  echo "Account: $ACCOUNT_ID" >&2
  echo "Refusing to continue." >&2
  exit 1
fi

echo "Resolving Stripe product for $PRODUCT_NAME ..."
if [[ -z "$PRODUCT_ID" ]]; then
  PRODUCT_ID="$(
    stripe_json products list --limit 100 \
      | jq -r --arg name "$PRODUCT_NAME" '.data[]? | select(.name == $name) | .id' \
      | head -n 1
  )"
fi

if [[ -z "$PRODUCT_ID" ]]; then
  PRODUCT_ID="$(
    stripe_json products create \
      --confirm \
      --name "$PRODUCT_NAME" \
      --description "$PRODUCT_DESCRIPTION" \
      --url "https://windowdrop.pro" \
      | jq -r '.id'
  )"
  require_nonempty_id "$PRODUCT_ID" "product id"
  echo "Created product: $PRODUCT_ID"
else
  echo "Using product: $PRODUCT_ID"
fi

PRODUCT_JSON="$(stripe_json products retrieve "$PRODUCT_ID")"
DEFAULT_PRICE_ID="$(echo "$PRODUCT_JSON" | jq -r '.default_price // empty')"

if [[ "$ARCHIVE_MONTHLY" == "1" ]]; then
  echo "Archiving active monthly recurring prices for this product..."
  MONTHLY_PRICE_IDS="$(
    stripe_json prices list \
      --product "$PRODUCT_ID" \
      --active \
      --limit 100 \
      | jq -r '.data[]? | select(.recurring != null and .recurring.interval == "month") | .id'
  )"

  if [[ -z "$MONTHLY_PRICE_IDS" ]]; then
    echo "No active monthly prices found."
  else
    while IFS= read -r monthly_price_id; do
      [[ -z "$monthly_price_id" ]] && continue
      if [[ -n "$DEFAULT_PRICE_ID" && "$monthly_price_id" == "$DEFAULT_PRICE_ID" ]]; then
        echo "Skipping monthly default price (cannot archive without changing product default): $monthly_price_id"
        continue
      fi
      stripe_json prices update "$monthly_price_id" --active=false --confirm >/dev/null
      echo "Archived monthly price: $monthly_price_id"
    done <<< "$MONTHLY_PRICE_IDS"
  fi
fi

echo "Resolving lifetime one-time price ($LIFETIME_AMOUNT_CENTS cents)..."
LIFETIME_PRICE_ID="$(
  stripe_json prices list \
    --product "$PRODUCT_ID" \
    --active \
    --limit 100 \
    | jq -r --argjson amount "$LIFETIME_AMOUNT_CENTS" '
        .data[]?
        | select(.type == "one_time")
        | select(.currency == "usd")
        | select(.unit_amount == $amount)
        | .id
      ' \
    | head -n 1
)"

if [[ -z "$LIFETIME_PRICE_ID" ]]; then
  LIFETIME_PRICE_ID="$(
    stripe_json prices create \
      --confirm \
      --product "$PRODUCT_ID" \
      --currency usd \
      --unit-amount "$LIFETIME_AMOUNT_CENTS" \
      --nickname "Lifetime" \
      | jq -r '.id'
  )"
  echo "Created lifetime price: $LIFETIME_PRICE_ID"
else
  echo "Reusing lifetime price: $LIFETIME_PRICE_ID"
fi
require_nonempty_id "$LIFETIME_PRICE_ID" "lifetime price id"

LIFETIME_REDIRECT_URL="$(append_plan_query "$REDIRECT_BASE" "lifetime")"

echo "Resolving lifetime payment link..."
LIFETIME_LINK_JSON="$(
  stripe_json payment_links list --limit 100 \
    | jq -c --arg product "$PRODUCT_ID" --arg price "$LIFETIME_PRICE_ID" '
        .data[]?
        | select(.active == true)
        | select(.metadata.windowdrop_plan == "lifetime")
        | select(.metadata.windowdrop_product_id == $product)
        | select(.metadata.windowdrop_price_id == $price)
      ' \
    | head -n 1
)"

if [[ -z "$LIFETIME_LINK_JSON" ]]; then
  LIFETIME_LINK_JSON="$(
    stripe_json payment_links create \
      --confirm \
      -d "line_items[0][price]=$LIFETIME_PRICE_ID" \
      -d "line_items[0][quantity]=1" \
      -d "allow_promotion_codes=true" \
      -d "metadata[windowdrop_plan]=lifetime" \
      -d "metadata[windowdrop_product_id]=$PRODUCT_ID" \
      -d "metadata[windowdrop_price_id]=$LIFETIME_PRICE_ID" \
      -d "after_completion[type]=redirect" \
      -d "after_completion[redirect][url]=$LIFETIME_REDIRECT_URL"
  )"
  echo "Created lifetime payment link."
else
  echo "Reusing lifetime payment link."
fi
LIFETIME_PLINK_ID="$(echo "$LIFETIME_LINK_JSON" | jq -r '.id')"
LIFETIME_URL="$(echo "$LIFETIME_LINK_JSON" | jq -r '.url')"
require_nonempty_id "$LIFETIME_PLINK_ID" "lifetime payment link id"
if [[ -z "$LIFETIME_URL" || "$LIFETIME_URL" == "null" ]]; then
  echo "ERROR: Missing lifetime payment link URL from Stripe response." >&2
  exit 1
fi

echo
echo "Done."
echo
echo "Product:               $PRODUCT_ID"
echo "Lifetime price:        $LIFETIME_PRICE_ID"
echo "Lifetime payment link: $LIFETIME_PLINK_ID"
echo
echo "Lifetime URL: $LIFETIME_URL"
echo
echo "Set in site config (or env-backed config):"
echo "  STRIPE_LIFETIME_URL=$LIFETIME_URL"
