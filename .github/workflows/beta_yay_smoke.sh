#!/usr/bin/env bash
set -euo pipefail

if [[ ${CI:-} ]]; then
  set -x
fi

if ! command -v yay >/dev/null; then
  echo "[beta-qa] yay not installed" >&2
  exit 1
fi

export YAYFLAGS="--noconfirm --nodiffmenu --noeditmenu --nocleanmenu"

if ! yay ${YAYFLAGS} --needed aur-scanner >/tmp/yay-install.log 2>&1; then
  cat /tmp/yay-install.log >&2
  echo "[beta-qa] failed to install aur-scanner via yay" >&2
  exit 1
fi

if ! command -v scan >/dev/null; then
  echo "[beta-qa] scan binary missing after yay install" >&2
  exit 1
fi

if ! command -v aur-verify >/dev/null; then
  echo "[beta-qa] aur-verify binary missing after yay install" >&2
  exit 1
fi

if ! aur-verify --help | grep -q "Usage: aur-verify.sh"; then
  echo "[beta-qa] aur-verify --help did not emit expected banner" >&2
  exit 1
fi

if ! scan --help | grep -q "Usage:"; then
  echo "[beta-qa] scan --help did not emit expected usage" >&2
  exit 1
fi

if ! scan yay -Syu --verify-only aur-scanner >/tmp/scan-run.log 2>&1; then
  cat /tmp/scan-run.log >&2
  echo "[beta-qa] scan command failed" >&2
  exit 1
fi

echo "[beta-qa] yay smoke test passed."
