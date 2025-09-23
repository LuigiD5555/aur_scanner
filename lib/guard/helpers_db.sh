# SPDX-License-Identifier: MIT
# Copyright (c) 2025 José Luis López López Prieto
# Author GitHub: https://github.com/LuigiD5555
# lib/guard/helpers_db.sh
# Load helpers.kind map from lib/guard/helpers.list

# Declared here so the caller can use it
declare -gA GUARD_HELPER_KIND=()

guard_load_helpers_map() {
  local f="${1:-$HELPERS_LIST}" line helper kind _
  if [[ ! -f "$f" ]]; then
    log_warn "helpers.list not found at: $f (defaulting to pacman style)"
    return 0
  fi
  while IFS= read -r line; do
    [[ -z "$line" || "$line" =~ ^[[:space:]]*# ]] && continue
    read -r helper kind _ <<<"$line"
    [[ -z "${helper:-}" || -z "${kind:-}" ]] && continue
    GUARD_HELPER_KIND["$helper"]="$kind"
  done < "$f"
}
