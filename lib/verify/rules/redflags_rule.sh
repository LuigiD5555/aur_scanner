#!/usr/bin/env bash
# SPDX-License-Identifier: MIT
# Copyright (c) 2025 José Luis López López Prieto
# Author GitHub: https://github.com/LuigiD5555
# redflags_rule.sh — static red flags handling (JS preferred when available)

rule_red_flags() { # $1=pkgb $2=strict
  local pkgb="$1" strict="$2" flags="" count=0
  # Prefer JS parser when available (diagnostics and better matching). Avoid extra Node calls.
  if js_parser_available; then
    if [ -n "${AUR_JS_SIG_RED_FLAGS:-}" ]; then
      count="$AUR_JS_SIG_RED_FLAGS"
    else
      count=$(js_pkgb_redflags_count "$pkgb" 2>/dev/null || echo 0)
    fi
    if [ "$count" -gt 0 ]; then
      if [ "${VERBOSE:-0}" = "1" ]; then
        local lines benign=1
        lines="$(js_pkgb_redflags_lines "$pkgb" 2>/dev/null || true)"
        if [ -n "$lines" ]; then
          while IFS= read -r ln; do
            local content; content="${ln#*\t}"
            if ! printf '%s' "$content" | grep -Eq '\$\(eval[[:space:]]+echo[[:space:]]+"?\$\{_[A-Za-z0-9_]+_\$CARCH\}"?\)'; then benign=0; break; fi
          done <<EOF
$lines
EOF
        fi
        if [ "$benign" = "1" ]; then
          log_warn "Red flags: eval used to select file by CPU architecture (low risk):"; printf '%s\n' "$lines" | sed 's/^/  /' >&2
          if [ "$strict" = "1" ]; then report_add "item_red_flags" "FAIL" "redflags_fail"; return 1; else report_add "item_red_flags" "WARN" "redflags_warn_arch_eval"; return 0; fi
        else
          log_warn "Potential red flags found in PKGBUILD (JS parser):"; printf '%s\n' "$lines" | sed 's/^/  /' >&2
          if [ "$strict" = "1" ]; then report_add "item_red_flags" "FAIL" "redflags_fail"; return 1; else report_add "item_red_flags" "WARN" "redflags_warn"; return 0; fi
        fi
      else
        # Non-verbose: report using count only (no extra Node invocation)
        if [ "$strict" = "1" ]; then report_add "item_red_flags" "FAIL" "redflags_fail"; return 1; else report_add "item_red_flags" "WARN" "redflags_warn"; return 0; fi
      fi
    else
      report_add "item_red_flags" "PASS" "redflags_ok"; return 0
    fi
  fi
  flags="$(scan_red_flags "$pkgb")"
  if [ -n "$flags" ]; then
    local eval_lines total_eval benign_fallback=0
    total_eval=$(grep -En 'eval' "$pkgb" | wc -l | tr -d ' ')
    eval_lines=$(grep -En '\$\(eval[[:space:]]+echo[[:space:]]+"?\$\{_[A-Za-z0-9_]+_\$CARCH\}"?\)' "$pkgb" | wc -l | tr -d ' ')
    if [ "$total_eval" -gt 0 ] && [ "$total_eval" -eq "$eval_lines" ]; then benign_fallback=1; fi
    if [ "$benign_fallback" = "1" ]; then
      [ "${VERBOSE:-0}" = "1" ] && { log_warn "Red flags: eval used to select file by CPU architecture (low risk):"; printf '%s\n' "$flags" | sed 's/^/  /' >&2; }
      if [ "$strict" = "1" ]; then report_add "item_red_flags" "FAIL" "redflags_fail"; return 1; else report_add "item_red_flags" "WARN" "redflags_warn_arch_eval"; return 0; fi
    else
      [ "${VERBOSE:-0}" = "1" ] && { log_warn "Potential red flags found in PKGBUILD:"; printf '%s\n' "$flags" | sed 's/^/  /' >&2; }
      if [ "$strict" = "1" ]; then report_add "item_red_flags" "FAIL" "redflags_fail"; return 1; else report_add "item_red_flags" "WARN" "redflags_warn"; return 0; fi
    fi
  else
    report_add "item_red_flags" "PASS" "redflags_ok"; return 0
  fi
}
