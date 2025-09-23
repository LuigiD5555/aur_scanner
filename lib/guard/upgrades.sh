# SPDX-License-Identifier: MIT
# Copyright (c) 2025 José Luis López López Prieto
# Author GitHub: https://github.com/LuigiD5555
# lib/guard/upgrades.sh
# Collect helper-specific upgrade candidates when running full upgrades.

guard_collect_upgrade_targets() {
  local helper_path="$1" kind="$2"
  local toolbase
  toolbase="$(basename -- "$helper_path")"

  local -a cmd=()
  case "$toolbase" in
    yay|paru|pikaur|trizen)
      cmd=("$helper_path" -Qum)
      ;;
    *)
      log_debug "upgrade scan not supported for helper: $toolbase"
      return 0
      ;;
  esac

  local line pkg
  declare -A seen=()

  while IFS= read -r line; do
    [[ -z "$line" ]] && continue
    if [[ $line =~ ^aur/([^[:space:]]+) ]]; then
      pkg="${BASH_REMATCH[1]}"
      if [[ -n "$pkg" && -z "${seen[$pkg]:-}" ]]; then
        printf '%s\n' "$pkg"
        seen["$pkg"]=1
      fi
    fi
  done < <("${cmd[@]}" 2>/dev/null)
}
