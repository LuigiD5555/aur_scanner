#!/usr/bin/env bash
# SPDX-License-Identifier: MIT
# Copyright (c) 2025 José Luis López López Prieto
# Author GitHub: https://github.com/LuigiD5555
# uninstall-aur-guard.sh — Remove aur-guard helper symlinks.

set -euo pipefail
IFS=$'\n\t'

usage() {
  cat <<'EOF'
Usage: scripts/uninstall-aur-guard.sh [--user|--system]

Options:
  --user          Remove symlinks from ~/.local/bin (default).
  --system        Remove symlinks from /usr/local/bin (requires root).

Notes:
  - Deletes helper symlinks created by scripts/install-aur-guard.sh when they
    still point to bin/aur-guard inside this repository.
  - Leaves other executables intact and ignores helpers that were not wrapped.
EOF
}

mode="user"

for arg in "$@"; do
  case "$arg" in
    --user) mode="user" ;;
    --system) mode="system" ;;
    -h|--help) usage; exit 0 ;;
    *) echo "Unknown option: $arg" >&2; usage; exit 2 ;;
  esac
done

SCRIPT_DIR=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)
ROOT_DIR=$(cd -- "$SCRIPT_DIR/.." && pwd)
GUARD_TARGET="$(cd -- "$ROOT_DIR/bin" && pwd)/aur-guard"

helpers=(yay paru pikaur trizen pamac)

if [ "$mode" = "user" ]; then
  dest="$HOME/.local/bin"
  note="[uninstall]"
else
  dest="/usr/local/bin"
  note="[uninstall]"
  if [ ! -w "$dest" ]; then
    echo "$note $dest requires elevated permissions. Try: sudo \"$0\" --system" >&2
    exit 1
  fi
fi

[ -d "$dest" ] || { echo "$note Directory $dest does not exist. Nothing to do."; exit 0; }

removed=0
for helper in "${helpers[@]}"; do
  candidate="$dest/$helper"
  [ -e "$candidate" ] || continue
  if [ -L "$candidate" ]; then
    target="$(readlink -f "$candidate" 2>/dev/null || readlink "$candidate" 2>/dev/null || true)"
    if [ "${target:-}" = "$GUARD_TARGET" ]; then
      rm -f "$candidate"
      echo "$note Removed $candidate"
      removed=1
      continue
    fi
  fi
  echo "$note Skipped $candidate (not a symlink to aur-guard)"
done

if [ "$removed" -eq 0 ]; then
  echo "$note No aur-guard symlinks found in $dest"
else
  echo "$note Finished. Verify your PATH if you added ~/.local/bin manually."
fi
