# SPDX-License-Identifier: MIT
# Copyright (c) 2025 José Luis López <ing.jlllopezp@gmail.com>
# Author GitHub: https://github.com/LuigiD5555
# js_signals_rule.sh — consume Node/JS signals, export them for other rules, and report per-dimension + summary

# rule_js_signals $1=pkgb $2=strict
rule_js_signals() {
  local pkgb="$1" strict="$2"

  # 0) Guard: if helper not present, be explicit in report (SKIP)
  if ! command -v js_parser_available >/dev/null 2>&1; then
    report_add "item_js_signals" "SKIP" "js_signals_unavailable"
    return 0
  fi

  if ! js_parser_available; then
    report_add "item_js_signals" "SKIP" "js_signals_unavailable"
    return 0
  fi

  # 1) Single Node call to get signals for this PKGBUILD
  #    Expected format (key=value per line): unpinnedGit=0|N, nonHttps=0|N, redFlags=0|N
  local sig
  sig="$(js_pkgb_signals "$pkgb" 2>/dev/null || true)"

  if [ -z "$sig" ]; then
    # No data from parser → consider as "no signals"
    report_add "item_js_signals" "PASS" "js_signals_none"
    return 0
  fi

  # 2) Parse counts
  local unpinnedGit nonHttps redFlags
  unpinnedGit=$(printf '%s\n' "$sig" | awk -F= '/^unpinnedGit=/{print $2+0}')
  nonHttps=$(printf '%s\n' "$sig" | awk -F= '/^nonHttps=/{print $2+0}')
  redFlags=$(printf '%s\n' "$sig" | awk -F= '/^redFlags=/{print $2+0}')

  # 3) Export for other rules (keep both spellings for compatibility)
  export AUR_JS_SIG_UNPINNED_GIT="$unpinnedGit"
  export AUR_JS_SIG_NON_HTTPS="$nonHttps"
  export AUR_JS_SIG_NONHTTPS_SRCS="$nonHttps"   # alt spelling used by some rules
  export AUR_JS_SIG_RED_FLAGS="$redFlags"

  # 4) Per-dimension reporting (keep original item names and keys)
  local any_bad=0

  if [ "$unpinnedGit" -gt 0 ]; then
    any_bad=1
    if [ "$strict" = "1" ]; then
      report_add "item_js_git_pinning" "FAIL" "js_git_unpinned_fail"
    else
      report_add "item_js_git_pinning" "WARN" "js_git_unpinned_warn"
    fi
  else
    report_add "item_js_git_pinning" "PASS" "js_git_pinned_ok"
  fi

  if [ "$nonHttps" -gt 0 ]; then
    any_bad=1
    if [ "$strict" = "1" ]; then
      report_add "item_js_https" "FAIL" "js_https_fail"
    else
      report_add "item_js_https" "WARN" "js_https_warn"
    fi
  else
    report_add "item_js_https" "PASS" "js_https_ok"
  fi

  if [ "$redFlags" -gt 0 ]; then
    any_bad=1
    if [ "$strict" = "1" ]; then
      report_add "item_js_redflags" "FAIL" "js_redflags_fail"
    else
      report_add "item_js_redflags" "WARN" "js_redflags_warn"
    fi
  else
    report_add "item_js_redflags" "PASS" "js_redflags_ok"
  fi

  # 5) Summary item (new): mirrors suggested’s clarity while keeping originals
  if [ "$any_bad" -eq 0 ]; then
    report_add "item_js_signals" "PASS" "js_signals_ok"
    return 0
  fi

  if [ "$strict" = "1" ]; then
    report_add "item_js_signals" "FAIL" "js_signals_fail_strict"
    return 1
  else
    report_add "item_js_signals" "WARN" "js_signals_warn"
    return 0
  fi
}
