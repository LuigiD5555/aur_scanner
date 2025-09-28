#!/usr/bin/env bash
set -euo pipefail

[[ ${CI:-} ]] && set -x

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

YAY_FLAGS="--noconfirm --needed --answerdiff None --answerclean None"

if ! su builder -c "yay $YAY_FLAGS aur-scanner" >/tmp/yay-install.log 2>&1; then
  cat /tmp/yay-install.log >&2
  echo "[beta-qa] failed to install aur-scanner via yay" >&2
  exit 1
fi

for bin in scan aur-verify; do
  if ! command -v "$bin" >/dev/null 2>&1; then
    echo "[beta-qa] $bin binary missing after yay install" >&2
    exit 1
  fi
done

aur-verify --help | grep -q "Usage: aur-verify.sh" || {
  echo "[beta-qa] aur-verify --help did not emit expected banner" >&2
  exit 1
}

scan --help | grep -q "Usage:" || {
  echo "[beta-qa] scan --help did not emit expected usage" >&2
  exit 1
}

if ! su builder -c "scan yay -Syu --verify-only aur-scanner" >/tmp/scan-run.log 2>&1; then
  cat /tmp/scan-run.log >&2
  echo "[beta-qa] scan wrapper invocation failed" >&2
  exit 1
fi

echo "[beta-qa] yay smoke test passed."
