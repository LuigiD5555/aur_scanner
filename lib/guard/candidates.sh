# SPDX-License-Identifier: MIT
# Copyright (c) 2025 José Luis López López Prieto
# Author GitHub: https://github.com/LuigiD5555
# lib/guard/candidates.sh
# Extract candidate targets (packages) depending on helper kind

declare -g GUARD_UPGRADE_MODE=0

guard_collect_targets_pacman_style() {
  # pacman-like: packages commonly after -S / -U and any non-flag tokens
  local args=("$@") a have_action=0 upgrade_all=0 targets=()
  GUARD_UPGRADE_MODE=0
  for a in "${args[@]}"; do
    if [[ "$a" == -* ]]; then
      if [[ "$a" =~ ^-S ]]; then
        have_action=1
        [[ "$a" == *u* ]] && upgrade_all=1
      fi
      [[ "$a" =~ ^-U ]] && have_action=1
      [[ "$a" == "-u" ]] && upgrade_all=1
      continue
    fi
    targets+=("$a")
  done
  if [[ $have_action -eq 1 && ${#targets[@]} -gt 0 ]]; then
    printf '%s\n' "${targets[@]}"
  elif [[ $have_action -eq 1 && $upgrade_all -eq 1 ]]; then
    GUARD_UPGRADE_MODE=1
  fi
}

guard_collect_targets_pamac_style() {
  # pamac: subcommands like build/install/upgrade followed by pkgs
  local args=("$@") sub="" a targets=()
  for a in "${args[@]}"; do
    if [[ -z "$sub" && "${a#-}" = "$a" ]]; then
      sub="$a"; continue
    fi
    if [[ "$a" != -* ]]; then
      targets+=("$a")
    fi
  done
  case "$sub" in
    build|install|upgrade)
      [[ ${#targets[@]} -gt 0 ]] && printf '%s\n' "${targets[@]}"
      ;;
    *) : ;;
  esac
}
