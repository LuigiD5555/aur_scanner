#!/usr/bin/env bash
# SPDX-License-Identifier: MIT
# Copyright (c) 2025 José Luis López López Prieto <ing.jlllopezp@gmail.com>
# Author GitHub: https://github.com/LuigiD5555
# js_signals_rule.sh — use Node parser signals to enrich report

rule_js_signals() { # $1=pkgb $2=strict
  local pkgb="$1" strict="$2"
  js_parser_available || return 0
  local sig; sig="$(js_pkgb_signals "$pkgb" 2>/dev/null || true)"
  [ -n "$sig" ] || return 0
  local unpinnedGit nonHttps redFlags
  unpinnedGit=$(printf '%s\n' "$sig" | awk -F= '/^unpinnedGit=/{print $2+0}')
  nonHttps=$(printf '%s\n' "$sig" | awk -F= '/^nonHttps=/{print $2+0}')
  redFlags=$(printf '%s\n' "$sig" | awk -F= '/^redFlags=/{print $2+0}')
  # Export counts for other rules to avoid extra Node invocations
  export AUR_JS_SIG_UNPINNED_GIT="$unpinnedGit"
  export AUR_JS_SIG_NON_HTTPS="$nonHttps"
  export AUR_JS_SIG_RED_FLAGS="$redFlags"

  if [ "$unpinnedGit" -gt 0 ]; then
    if [ "$strict" = "1" ]; then report_add "item_js_git_pinning" "FAIL" "js_git_unpinned_fail"; else report_add "item_js_git_pinning" "WARN" "js_git_unpinned_warn"; fi
  else
    report_add "item_js_git_pinning" "PASS" "js_git_pinned_ok"
  fi

  if [ "$nonHttps" -gt 0 ]; then
    if [ "$strict" = "1" ]; then report_add "item_js_https" "FAIL" "js_https_fail"; else report_add "item_js_https" "WARN" "js_https_warn"; fi
  else
    report_add "item_js_https" "PASS" "js_https_ok"
  fi

  if [ "$redFlags" -gt 0 ]; then
    if [ "$strict" = "1" ]; then report_add "item_js_redflags" "FAIL" "js_redflags_fail"; else report_add "item_js_redflags" "WARN" "js_redflags_warn"; fi
  else
    report_add "item_js_redflags" "PASS" "js_redflags_ok"
  fi
}
