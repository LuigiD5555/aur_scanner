#!/usr/bin/env bash
set -euo pipefail

if [[ ${CI:-} ]]; then
  set -x
fi

ensure_yay() {
  if command -v yay >/dev/null 2>&1; then
    return 0
  fi

  pacman -S --noconfirm --needed git base-devel

  if ! id builder >/dev/null 2>&1; then
    useradd -m builder
    echo 'builder ALL=(ALL) NOPASSWD: ALL' >> /etc/sudoers
  fi

  su builder -c '
    set -euo pipefail
    WORKDIR=$(mktemp -d)
    trap "rm -rf \"$WORKDIR\"" EXIT
    cd "$WORKDIR"
    git clone https://aur.archlinux.org/yay.git
    cd yay
    makepkg -si --noconfirm
  '
}

pacman -Syu --noconfirm
ensure_yay

export YAYFLAGS="--noconfirm --nodiffmenu --noeditmenu --nocleanmenu"

yay ${YAYFLAGS} --needed aur-scanner >/tmp/yay-install.log 2>&1 || {
  cat /tmp/yay-install.log >&2
  echo "[beta-qa] failed to install aur-scanner via yay" >&2
  exit 1
}

if ! command -v scan >/dev/null 2>&1; then
  echo "[beta-qa] scan binary missing after yay install" >&2
  exit 1
fi

if ! command -v aur-verify >/dev/null 2>&1; then
  echo "[beta-qa] aur-verify binary missing after yay install" >&2
  exit 1
fi

aur-verify --help | grep -q "Usage: aur-verify.sh" || {
  echo "[beta-qa] aur-verify --help did not emit expected banner" >&2
  exit 1
}

scan --help | grep -q "Usage:" || {
  echo "[beta-qa] scan --help did not emit expected usage" >&2
  exit 1
}

scan yay -Syu --verify-only aur-scanner >/tmp/scan-run.log 2>&1 || {
  cat /tmp/scan-run.log >&2
  echo "[beta-qa] scan wrapper invocation failed" >&2
  exit 1
}

echo "[beta-qa] yay smoke test passed."
