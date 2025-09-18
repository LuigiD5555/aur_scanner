#!/usr/bin/env bash
# SPDX-License-Identifier: MIT
# Copyright (c) 2025 José Luis López López Prieto
# Author GitHub: https://github.com/LuigiD5555
# js_parser_bridge.sh — thin Bash wrappers around the Node PKGBUILD parser

SCRIPT_DIR=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)
ROOT_DIR="$SCRIPT_DIR/.."

_js_bin() {
  # Prefer invoking via node for reliability in shells that ignore shebangs
  if have_cmd node && [ -f "$ROOT_DIR/bin/pkgb-parse" ]; then
    printf 'node %s\n' "$ROOT_DIR/bin/pkgb-parse"
    return 0
  fi
  return 1
}

js_parser_available() {
  _js_bin >/dev/null 2>&1
}

js_pkgb_parse_summary() { # $1=PKGBUILD
  local pkgb="$1"; local bin; bin="$(_js_bin)" || return 1
  $bin --file "$pkgb" --summary
}

js_pkgb_signals() { # $1=PKGBUILD
  local pkgb="$1"; local bin; bin="$(_js_bin)" || return 1
  $bin --file "$pkgb" --signals
}

js_pkgb_redflags_lines() { # $1=PKGBUILD
  local pkgb="$1"; local bin; bin="$(_js_bin)" || return 1
  $bin --file "$pkgb" --redflags-lines
}

js_pkgb_redflags_count() { # $1=PKGBUILD
  local pkgb="$1"; js_pkgb_redflags_lines "$pkgb" | wc -l | tr -d ' '
}

js_pkgb_sources_compact() { # $1=PKGBUILD [$2=limit]
  local pkgb="$1" limit="${2:-0}"; local bin; bin="$(_js_bin)" || return 1
  if [ "$limit" -gt 0 ] 2>/dev/null; then
    $bin --file "$pkgb" --sources-compact --limit "$limit"
  else
    $bin --file "$pkgb" --sources-compact
  fi
}
