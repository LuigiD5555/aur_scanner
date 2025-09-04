#!/usr/bin/env bash
# install-aur-guard.sh — Set up aur-guard symlinks automatically

set -euo pipefail
IFS=$'\n\t'

usage() {
  cat <<'EOF'
Usage: scripts/install-aur-guard.sh [--user|--system]

Options:
  --user          Install symlinks into ~/.local/bin (default)
  --system        Install symlinks into /usr/local/bin (requires root)

Notes:
  - Creates symlinks named after known AUR helpers so that they run pre-checks
    via bin/aur-guard before delegating to the real binary.
  - Puts ~/.local/bin at the beginning of PATH in ~/.profile if needed (user mode).
  - You can safely re-run this script to refresh symlinks.
EOF
}

mode="user"
wrap_pacman=0
for arg in "$@"; do
  case "$arg" in
    --user) mode="user" ;;
    --system) mode="system" ;;
    --wrap-pacman) echo "--wrap-pacman is no longer supported" >&2; exit 2 ;;
    -h|--help) usage; exit 0 ;;
    *) echo "Unknown option: $arg" >&2; usage; exit 2 ;;
  esac
done

# Resolve repo root (this script is in scripts/)
SCRIPT_DIR=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)
ROOT_DIR=$(cd -- "$SCRIPT_DIR/.." && pwd)
GUARD="$ROOT_DIR/bin/aur-guard"
[ -x "$GUARD" ] || { echo "bin/aur-guard not found or not executable" >&2; exit 1; }

# Known helpers to wrap (add more if needed)
helpers=(yay paru pikaur trizen pamac)
:

if [ "$mode" = "user" ]; then
  dest="$HOME/.local/bin"
  mkdir -p "$dest"
  for h in "${helpers[@]}"; do
    ln -sf "$GUARD" "$dest/$h"
    echo "[install] Linked $dest/$h -> $GUARD"
  done
  # Ensure ~/.local/bin is at the beginning of PATH on next logins
  prof="$HOME/.profile"
  ensure_line='export PATH="$HOME/.local/bin:$PATH"'
  if ! grep -Fq "$ensure_line" "$prof" 2>/dev/null; then
    echo "$ensure_line" >> "$prof"
    echo "[install] Added ~/.local/bin to PATH in $prof"
  fi
  echo "[install] Done. Open a new shell or run: export PATH=\"$HOME/.local/bin:$PATH\""
else
  dest="/usr/local/bin"
  if [ ! -w "$dest" ]; then
    echo "[install] /usr/local/bin requires root. Try: sudo $0 --system" >&2
    exit 1
  fi
  for h in "${helpers[@]}"; do
    ln -sf "$GUARD" "$dest/$h"
    echo "[install] Linked $dest/$h -> $GUARD"
  done
  echo "[install] Done. Ensure /usr/local/bin precedes /usr/bin in PATH."
fi
