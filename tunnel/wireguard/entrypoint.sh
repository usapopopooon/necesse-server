#!/bin/sh
set -eu

WG_CONF_PATH="/config/wg_confs/wg0.conf"

if [ -n "${WG0_CONF_B64:-}" ]; then
  mkdir -p "$(dirname "$WG_CONF_PATH")"

  tmp_conf="$(mktemp)"
  clean_b64="$(printf '%s' "$WG0_CONF_B64" | tr -d '[:space:]')"

  if printf '%s' "$WG0_CONF_B64" | grep -q '^\[Interface\]'; then
    printf '%s\n' "$WG0_CONF_B64" > "$tmp_conf"
  elif ! printf '%s' "$clean_b64" | base64 -d > "$tmp_conf" 2>/dev/null; then
    rm -f "$tmp_conf"
    echo "WG0_CONF_B64 is not valid base64. Paste only the base64 output, without quotes, angle brackets, or command text." >&2
    exit 1
  fi

  if ! grep -q '^\[Interface\]' "$tmp_conf" || ! grep -q '^\[Peer\]' "$tmp_conf"; then
    rm -f "$tmp_conf"
    echo "Decoded WireGuard config is invalid. It must contain [Interface] and [Peer] sections." >&2
    exit 1
  fi

  mv "$tmp_conf" "$WG_CONF_PATH"
  chmod 600 "$WG_CONF_PATH"
fi

if [ ! -s "$WG_CONF_PATH" ]; then
  echo "WireGuard config is missing. Set WG0_CONF_B64 to base64-encoded wg0.conf." >&2
  exit 1
fi

if ! sysctl -w net.ipv4.conf.all.src_valid_mark=1 >/dev/null 2>&1; then
  echo "Warning: could not set net.ipv4.conf.all.src_valid_mark=1" >&2
fi

exec /init
