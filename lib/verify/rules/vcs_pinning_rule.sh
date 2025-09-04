#!/usr/bin/env bash
# License: CC BY-NC-SA 4.0 (https://creativecommons.org/licenses/by-nc-sa/4.0/)
# Copyright (c) 2025 José Luis López López Prieto
# vcs_pinning_rule.sh — enforce VCS pinning for git+ sources

rule_vcs_pinning() { # $1=pkgb $2=strict -> sets report items
  local pkgb="$1" strict="$2"
  if ! pkgb_check_vcs_pinning "$pkgb"; then
    if [ "$strict" = "1" ]; then
      report_add "item_vcs_pinning" "FAIL" "vcs_unpinned_fail"; return 1
    else
      report_add "item_vcs_pinning" "WARN" "vcs_unpinned_warn"; return 0
    fi
  else
    report_add "item_vcs_pinning" "PASS" "vcs_pinned_ok"; return 0
  fi
}
