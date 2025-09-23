#!/usr/bin/env bash
# SPDX-License-Identifier: MIT
# Copyright (c) 2025 José Luis López López Prieto <ing.jlllopezp@gmail.com>
# Author GitHub: https://github.com/LuigiD5555
# uninstall-scanner.sh — Full cleanup by default: remove helper symlinks, purge staged runtime, and clean PATH.

set -euo pipefail
IFS=$'\n\t'

usage() {
  cat <<'EOF'
Usage: scripts/uninstall-scanner.sh [--user|--system] [--no-purge] [--no-path] [--dry-run]

Defaults:
  - Removes helper symlinks (yay/paru/pikaur/trizen/pamac).
  - Purges the staged runtime directory (PREFIX_LIB).
  - Removes the PATH line: export PATH="$HOME/.local/bin:$PATH" from common dotfiles.

Options:
  --user        Operate under ~/.local (default).
  --system      Operate under /usr/local (requires root).
  --no-purge    Do NOT delete the staged runtime directory.
  --no-path     Do NOT edit dotfiles to remove the PATH line.
  --dry-run     Print actions without performing changes.

Notes:
  - Only removes helper symlinks if they point to the staged scan wrapper (safe).
  - Leaves unrelated executables intact.
EOF
}

# --- Flags (full cleanup by default) ---
mode="user"
purge="1"
remove_path="1"
dry_run="0"

for arg in "$@"; do
  case "$arg" in
    --user) mode="user" ;;
    --system) mode="system" ;;
    --no-purge) purge="0" ;;
    --no-path) remove_path="0" ;;
    --dry-run) dry_run="1" ;;
    -h|--help) usage; exit 0 ;;
    *) echo "[uninstall] Unknown option: $arg" >&2; usage; exit 2 ;;
  esac
done

log() { echo "[uninstall] $*"; }
do_or_echo() {
  if [ "$dry_run" = "1" ]; then
    log "(dry-run) $*"
  else
    eval "$@"
  fi
}

# --- Layout / targets ---
SCRIPT_DIR=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)
ROOT_DIR=$(cd -- "$SCRIPT_DIR/.." && pwd)

if [ "$mode" = "user" ]; then
  dest="$HOME/.local/bin"
  prefix_lib="$HOME/.local/lib/scan"
else
  dest="/usr/local/bin"
  prefix_lib="/usr/local/lib/scan"
  if [ ! -w "$dest" ] && [ "$dry_run" = "0" ]; then
    log "$dest requires elevated permissions. Try: sudo \"$0\" --system"
    exit 1
  fi
fi

helpers=(yay paru pikaur trizen pamac)

# Valid symlink targets we consider ours
valid_targets=()
# Staged target (preferred)
valid_targets+=("$prefix_lib/bin/scan")
valid_targets+=("$prefix_lib/bin/scan-shim")
# Legacy direct-repo target (in case older installs linked to repo files)
if [ -x "$ROOT_DIR/bin/scan" ]; then
  valid_targets+=("$ROOT_DIR/bin/scan")
fi
if [ -x "$ROOT_DIR/bin/scan-shim" ]; then
  valid_targets+=("$ROOT_DIR/bin/scan-shim")
fi

# --- Remove helper symlinks (only if they point to our targets) ---
if [ ! -d "$dest" ]; then
  log "Directory $dest does not exist. Nothing to do for symlinks."
else
  found=0
  for helper in "${helpers[@]}"; do
    candidate="$dest/$helper"
    [ -e "$candidate" ] || continue
    if [ -L "$candidate" ]; then
      target="$(readlink -f "$candidate" 2>/dev/null || readlink "$candidate" 2>/dev/null || true)"
      for v in "${valid_targets[@]}"; do
        if [ "${target:-}" = "$v" ]; then
          do_or_echo "rm -f \"$candidate\""
          log "Removed $candidate"
          found=1
          break
        fi
      done
    else
      log "Skipped $candidate (not a symlink)"
    fi
  done
  if [ "$found" -eq 0 ]; then
    log "No scan symlinks found in $dest"
  fi
fi

# --- Purge staged runtime directory (default ON) ---
if [ "$purge" = "1" ]; then
  if [ -d "$prefix_lib" ]; then
    do_or_echo "rm -rf \"$prefix_lib\""
    log "Purged staged runtime at $prefix_lib"
  else
    log "Nothing to purge at $prefix_lib"
  fi
fi

# --- Remove PATH line from common dotfiles (default ON) ---
remove_path_line() {
  # Remove the exact line from a file if present (idempotent, safe)
  local file="$1"
  local line='export PATH="$HOME/.local/bin:$PATH"'
  [ -f "$file" ] || return 0
  if grep -Fqx "$line" "$file" 2>/dev/null; then
    if [ "$dry_run" = "1" ]; then
      log "(dry-run) Would remove PATH line from $file"
    else
      tmp="$(mktemp)"
      # Keep everything except the exact line
      grep -Fvx "$line" "$file" > "$tmp" || true
      mv "$tmp" "$file"
      log "Removed PATH line from $file"
    fi
  fi
}

if [ "$remove_path" = "1" ]; then
  # We only ever add this to user dotfiles; still harmless to check both shells.
  remove_path_line "$HOME/.profile"
  remove_path_line "$HOME/.bashrc"
  remove_path_line "$HOME/.zprofile"
  remove_path_line "$HOME/.zshrc"
fi

# --- Try to refresh current shell hash table (best-effort, no failure) ---
if [ "$dry_run" = "0" ]; then
  if [ -n "${ZSH_VERSION-}" ]; then
    { rehash && log "zsh rehash done"; } || true
  fi
  if [ -n "${BASH_VERSION-}" ]; then
    { hash -r && log "bash hash refresh done"; } || true
  fi
fi

log "Finished."
