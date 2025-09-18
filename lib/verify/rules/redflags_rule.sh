#!/usr/bin/env bash
# SPDX-License-Identifier: MIT
# Copyright (c) 2025 José Luis López López Prieto
# Author GitHub: https://github.com/LuigiD5555
# redflags_rule.sh — static red flags handling (JS preferred when available)

# rule_red_flags $1=pkgb $2=strict
# Uses JS signal when available; otherwise falls back to conservative Bash heuristics.
rule_red_flags() {
  local pkgb="$1" strict="$2"

  # 1) Prefer the JS parser/signal if available
  if command -v js_parser_available >/dev/null 2>&1 && js_parser_available; then
    local count=0
    if [ -n "${AUR_JS_SIG_RED_FLAGS:-}" ]; then
      count="$AUR_JS_SIG_RED_FLAGS"
    else
      if command -v js_pkgb_redflags_count >/dev/null 2>&1; then
        count="$(js_pkgb_redflags_count "$pkgb" 2>/dev/null || echo 0)"
      else
        count=0
      fi
    fi

    if [ "$count" -gt 0 ]; then
      if [ "$strict" = "1" ]; then
        report_add "item_red_flags" "FAIL" "redflags_fail"
        return 1
      else
        report_add "item_red_flags" "WARN" "redflags_warn"
        return 0
      fi
    else
      report_add "item_red_flags" "PASS" "redflags_ok"
      return 0
    fi
  fi

  # 2) Bash fallback heuristics (conservadoras) para el fixture de tests:
  #    - pipe a sh/bash (e.g., curl ... | sh)
  #    - uso de eval
  #    - uso de "bash -c"
  local has_pipe_sh=0
  local has_eval=0
  local has_bash_c=0

  grep -Eqi '\|\s*(sh|bash)\b' "$pkgb" && has_pipe_sh=1
  grep -Eq '\beval\b' "$pkgb" && has_eval=1
  grep -Eq 'bash[[:space:]]+-c' "$pkgb" && has_bash_c=1

  if [ $((has_pipe_sh + has_eval + has_bash_c)) -gt 0 ]; then
    if [ "$strict" = "1" ]; then
      report_add "item_red_flags" "FAIL" "redflags_fail"
      return 1
    else
      report_add "item_red_flags" "WARN" "redflags_warn"
      return 0
    fi
  fi

  report_add "item_red_flags" "PASS" "redflags_ok"
  return 0
}
