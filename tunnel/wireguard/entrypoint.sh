#!/bin/sh
set -eu

WG_CONF_PATH="/config/wg_confs/wg0.conf"

if [ -n "${WG0_CONF_B64:-}" ]; then
  mkdir -p "$(dirname "$WG_CONF_PATH")"
  printf '%s' "$WG0_CONF_B64" | base64 -d > "$WG_CONF_PATH"
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
