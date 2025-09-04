#!/usr/bin/env bash
# verifysource_rule.sh — run makepkg --verifysource according to mode

rule_verifysource() { # $1=checkout $2=mode (fast|verify-only|full) $3=strict
  local checkout="$1" mode="$2" strict="$3"
  case "$mode" in
    verify-only)
      report_add "item_makepkg_verifysource" "SKIP" "verifysource_skip_verifyonly"; return 0;;
    fast)
      report_add "item_makepkg_verifysource" "SKIP" "verifysource_skip_fast"; return 0;;
    full)
      if (cd "$checkout" && makepkg --noconfirm --nodeps --verifysource); then
        report_add "item_makepkg_verifysource" "PASS" "verifysource_ok"; return 0
      else
        if [ "$strict" = "1" ]; then
          report_add "item_makepkg_verifysource" "FAIL" "verifysource_fail_strict"; return 1
        else
          report_add "item_makepkg_verifysource" "WARN" "verifysource_fail"; return 0
        fi
      fi
      ;;
  esac
}

