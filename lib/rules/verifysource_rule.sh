# SPDX-License-Identifier: MIT
# Copyright (c) 2025 José Luis López López Prieto
# Author GitHub: https://github.com/LuigiD5555
# verifysource_rule.sh — run makepkg --verifysource according to mode

# rule_verifysource $1=checkout_dir $2=mode(fast|verify-only|full) $3=strict(0|1)
# Produces a report item: SKIP/PASS/WARN/FAIL and exit code 0/1.
rule_verifysource() {
  local checkout="$1"
  local mode="${2:-verify-only}"
  local strict="${3:-0}"

  # Normalize mode (common aliases)
  case "$mode" in
    verify|verifyonly|verify-only|"") mode="verify-only" ;;
    quick|fast)                      mode="fast" ;;
    deep|full)                       mode="full" ;;
  esac

  # Basic validation
  if [[ -z "$checkout" || ! -d "$checkout" ]]; then
    if [[ "$strict" == "1" ]]; then
      report_add "item_makepkg_verifysource" "FAIL" "verifysource_no_checkout_strict"
      return 1
    else
      report_add "item_makepkg_verifysource" "WARN" "verifysource_no_checkout"
      return 0
    fi
  fi

  # Skip if verify-only or fast; only 'full' runs makepkg
  case "$mode" in
    verify-only)
      report_add "item_makepkg_verifysource" "SKIP" "verifysource_skip_verifyonly"
      return 0
      ;;
    fast)
      report_add "item_makepkg_verifysource" "SKIP" "verifysource_skip_fast"
      return 0
      ;;
    full)
      ;;
    *)
      report_add "item_makepkg_verifysource" "SKIP" "verifysource_skip_unknown_mode"
      return 0
      ;;
  esac

  # FULL mode: run makepkg --verifysource in a subshell
  if (
    cd "$checkout" \
      && command -v makepkg >/dev/null 2>&1 \
      && makepkg --noconfirm --nodeps --verifysource
  ); then
    report_add "item_makepkg_verifysource" "PASS" "verifysource_ok"
    return 0
  else
    if [[ "$strict" == "1" ]]; then
      report_add "item_makepkg_verifysource" "FAIL" "verifysource_fail_strict"
      return 1
    else
      report_add "item_makepkg_verifysource" "WARN" "verifysource_fail"
      return 0
    fi
  fi
}
