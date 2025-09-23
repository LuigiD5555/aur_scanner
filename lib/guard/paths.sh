# SPDX-License-Identifier: MIT
# Copyright (c) 2025 José Luis López López Prieto
# Author GitHub: https://github.com/LuigiD5555
# lib/guard/paths.sh
# Resolve paths and important locations

# Resolve self path
_guard_resolve_self() {
  _self_path="${BASH_SOURCE[1]:-$(command -v scan || true)}"
  if command -v readlink >/dev/null 2>&1; then
    local _resolved
    _resolved="$(readlink -f "$_self_path" 2>/dev/null || true)"
    [[ -n "${_resolved:-}" ]] && _self_path="$_resolved"
  fi
  SCRIPT_DIR="$(cd -- "$(dirname -- "$_self_path")" && pwd)"
  ROOT_DIR="$(cd -- "$SCRIPT_DIR/../.." && pwd)"  # because this file is lib/guard/*.sh
}

_guard_set_constants() {
  HELPERS_LIST="$ROOT_DIR/lib/guard/helpers.list"
  AUR_VERIFY_BIN="$ROOT_DIR/bin/aur-verify"
}

# Public init
guard_init_paths() {
  _guard_resolve_self
  _guard_set_constants
}
