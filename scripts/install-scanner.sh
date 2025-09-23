#!/usr/bin/env bash
# SPDX-License-Identifier: MIT
# Copyright (c) 2025 José Luis López López Prieto <ing.jlllopezp@gmail.com>
# Author GitHub: https://github.com/LuigiD5555
# install-scanner.sh — Orchestrates staging + symlinks, sourcing small modules.

set -euo pipefail
IFS=$'\n\t'

# --- Locate repo root and source modules (in order) ---
SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd -- "$SCRIPT_DIR/.." && pwd)"

# Source modules
. "$REPO_ROOT/lib/install/env.sh"
. "$REPO_ROOT/lib/install/common.sh"
. "$REPO_ROOT/lib/install/stage.sh"
. "$REPO_ROOT/lib/install/node.sh"
. "$REPO_ROOT/lib/install/symlinks.sh"

# ---------- Args ----------
mode="user"
while (($#)); do
  case "$1" in
    --user)   mode="user" ;;
    --system) mode="system" ;;
    -h|--help) usage; exit 0 ;;
    *) die "Unknown option: $1" ;;
  esac
  shift
done

print_banner

# ---------- Prefixes ----------
if [[ "$mode" == "user" ]]; then
  PREFIX_LIB="$HOME/.local/lib/scan"
  DEST_BIN="$HOME/.local/bin"
else
  [[ "$EUID" -eq 0 ]] || die "Use --system as root."
  PREFIX_LIB="/usr/local/lib/scan"
  DEST_BIN="/usr/local/bin"
fi

# Safety guards
[[ -n "$PREFIX_LIB" && -n "$DEST_BIN" ]] || die "Empty PREFIX_LIB/DEST_BIN."
[[ "$PREFIX_LIB" != "/" && "$DEST_BIN" != "/" ]] || die "Refusing '/' as prefix."

mkdir -p "$PREFIX_LIB" "$DEST_BIN"

# ---------- Steps ----------
ensure_node   # requires Node >= $MIN_NODE
stage_runtime "$REPO_ROOT" "$PREFIX_LIB"

# Resolve wrapper path
GUARD_RESOLVED="$PREFIX_LIB/bin/$GUARD_BASENAME"
if [[ ! -x "$GUARD_RESOLVED" && -x "$PREFIX_LIB/bin/scan.sh" ]]; then
  GUARD_RESOLVED="$PREFIX_LIB/bin/scan.sh"
fi
[[ -x "$GUARD_RESOLVED" ]] || die "Wrapper not found/executable at $PREFIX_LIB/bin/{scan,scan.sh}"

SHIM_RESOLVED="$PREFIX_LIB/bin/scan-shim"
[[ -x "$SHIM_RESOLVED" ]] || die "Wrapper shim not found/executable at $PREFIX_LIB/bin/scan-shim"

# Symlinks (launcher + helpers)
link_launcher_and_helpers "$GUARD_RESOLVED" "$SHIM_RESOLVED" "$DEST_BIN" "${HELPERS[@]}"

# PATH for user mode
if [[ "$mode" == "user" ]]; then
  case "$(detect_shell)" in
    zsh)
      ensure_path_line "$HOME/.zprofile"
      ensure_path_line "$HOME/.zshrc"
      [[ -n "${ZSH_VERSION-}" && -f "$HOME/.zprofile" ]] && . "$HOME/.zprofile" || true
      command -v rehash >/dev/null 2>&1 && rehash || true
      ;;
    *)
      ensure_path_line "$HOME/.profile"
      ensure_path_line "$HOME/.bashrc"
      [[ -n "${BASH_VERSION-}" && -f "$HOME/.profile" ]] && . "$HOME/.profile" || true
      hash -r || true
      ;;
  esac
fi

log "Runtime staged at: $PREFIX_LIB"
log "Symlinks in:       $DEST_BIN"
echo "[install] Done. Open a new shell or run: export PATH=\"$HOME/.local/bin:\$PATH\""
