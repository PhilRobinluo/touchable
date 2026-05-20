#!/usr/bin/env bash
set -euo pipefail

IDENTITY="${TOUCHABLE_CODESIGN_IDENTITY:-TouchAble Local Dev}"
KEYCHAIN="${HOME}/Library/Keychains/login.keychain-db"

can_sign_with_identity() {
  local tmpbin
  tmpbin="$(mktemp /tmp/touchable-sign-test-XXXXXX)"
  printf '#!/bin/sh\nexit 0\n' >"$tmpbin"
  chmod +x "$tmpbin"

  if /usr/bin/codesign --force --sign "$IDENTITY" --identifier "com.philrobin.TouchAble.sign-test" "$tmpbin" >/dev/null 2>&1; then
    rm -f "$tmpbin"
    return 0
  fi

  rm -f "$tmpbin"
  return 1
}

if can_sign_with_identity; then
  echo "TouchAble signing identity already works: $IDENTITY"
  exit 0
fi

tmpcert="$(mktemp /tmp/touchable-local-dev-XXXXXX.cer)"

# certtool creates a local self-signed signing certificate plus private key in
# the login keychain. The prompts are fed in this exact order:
# label, RSA, 2048, confirm, signing usage, SHA256, confirm, RDN fields, confirm.
printf '%s\nr\n2048\ny\ns\n2\ny\n%s\n\nPhil Local Development\nTouchAble\n\n\ny\n' "$IDENTITY" "$IDENTITY" |
  /usr/bin/certtool c "k=${KEYCHAIN}" "o=${tmpcert}" a u >/dev/null

rm -f "$tmpcert"

if can_sign_with_identity; then
  echo "Created TouchAble signing identity: $IDENTITY"
  exit 0
fi

echo "Failed to create a usable TouchAble signing identity: $IDENTITY" >&2
exit 1
