#!/usr/bin/env bash
# Configurable makepkg stub controlled via environment variables.
# Variables:
#   MAKEPKG_GENERATE_OUTPUT : content to echo during `makepkg -g`
#   MAKEPKG_GENERATE_STATUS : exit status for `makepkg -g` (default 0)
#   MAKEPKG_VERIFY_STATUS   : exit status for `makepkg --verifysource` (default 0)

set -euo pipefail

args=("$@")

is_generate=0
is_verify=0
for arg in "${args[@]}"; do
  case "$arg" in
    -g|--gen|--generate) is_generate=1 ;;
    --verifysource) is_verify=1 ;;
  esac
done

if [[ $is_generate -eq 1 ]]; then
  printf '%s\n' "${MAKEPKG_GENERATE_OUTPUT:-sha256sums=('stubbed')}"
  exit "${MAKEPKG_GENERATE_STATUS:-0}"
fi

if [[ $is_verify -eq 1 ]]; then
  exit "${MAKEPKG_VERIFY_STATUS:-0}"
fi

# Default fallback: succeed silently
exit 0
