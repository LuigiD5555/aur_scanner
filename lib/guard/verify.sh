# SPDX-License-Identifier: MIT
# Copyright (c) 2025 José Luis López López Prieto
# Author GitHub: https://github.com/LuigiD5555
# lib/guard/verify.sh
# Verification wrapper (calls bin/aur-verify on extracted targets)

guard_verify_aur_targets() {
  local real_helper="$1"; shift
  local toolbase kind
  toolbase="$(basename -- "$real_helper")"
  kind="${GUARD_HELPER_KIND[$toolbase]:-$toolbase}"
  local -a candidates=()
  local upgrade_mode=0

  unset SCAN_IGNORE_PKGS

  case "$kind" in
    pamac)    mapfile -t candidates < <(guard_collect_targets_pamac_style "$@") ;;
    pacman|*) mapfile -t candidates < <(guard_collect_targets_pacman_style "$@") ;;
  esac

  upgrade_mode=${GUARD_UPGRADE_MODE:-0}

  if [[ ${#candidates[@]} -eq 0 && $upgrade_mode -eq 1 ]]; then
    mapfile -t candidates < <(guard_collect_upgrade_targets "$real_helper" "$kind")
  fi

  if [[ ${#candidates[@]} -eq 0 ]]; then
    log_debug "no candidates extracted for verification"
    return 0
  fi

  if [[ -z "${AUR_VERIFY_BIN:-}" || ! -x "$AUR_VERIFY_BIN" ]]; then
    log_warn "aur-verify not found or not executable at: ${AUR_VERIFY_BIN:-<unset>} — delegating without verification"
    return 0
  fi

  if [[ $upgrade_mode -eq 1 ]]; then
    local -a failed=() passed=() rec
    for rec in "${candidates[@]}"; do
      if "$AUR_VERIFY_BIN" --verify-only -- "$rec"; then
        passed+=("$rec")
      else
        log_warn "Verification failed for $rec — scheduling to ignore"
        failed+=("$rec")
      fi
    done

    if [[ ${#failed[@]} -gt 0 ]]; then
      local csv
      csv=$(IFS=,; printf '%s' "${failed[*]}")
      export SCAN_IGNORE_PKGS="$csv"
    else
      unset SCAN_IGNORE_PKGS
    fi

    if [[ ${#passed[@]} -gt 0 ]]; then
      log_debug "verified AUR upgrades: ${passed[*]}"
    else
      log_warn "All AUR upgrades failed verification; helper will continue with ignores"
    fi
    return 0
  fi

  log_debug "verifying candidates: ${candidates[*]}"
  "$AUR_VERIFY_BIN" --verify-only -- "${candidates[@]}"
}
