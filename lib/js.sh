#!/usr/bin/env bash
# js.sh — helpers to use the Node.js PKGBUILD parser (optional)

js_parser_path() {
  local script_dir
  script_dir=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)
  printf '%s/../bin/pkgb-parse\n' "$script_dir"
}

js_parser_available() {
  local nodebin
  nodebin=$(command -v node || command -v nodejs || true)
  [ -n "$nodebin" ] && [ -x "$(js_parser_path)" ]
}

js_pkgb_parse_summary() { # $1=PKGBUILD path
  local nodebin
  nodebin=$(command -v node || command -v nodejs)
  "$nodebin" "$(js_parser_path)" --file "$1" --summary
}

js_pkgb_signals() { # $1=PKGBUILD path -> prints key=value lines
  local nodebin
  nodebin=$(command -v node || command -v nodejs)
  "$nodebin" "$(js_parser_path)" --file "$1" --signals
}

js_pkgb_redflags_lines() { # $1=PKGBUILD path -> prints "line\tcontent"
  local nodebin
  nodebin=$(command -v node || command -v nodejs)
  "$nodebin" "$(js_parser_path)" --file "$1" --redflags-lines
}

js_pkgb_redflags_count() { # $1=PKGBUILD path -> echoes number
  js_pkgb_signals "$1" 2>/dev/null | awk -F= '$1=="redFlags" {print $2; found=1} END{if(!found) print 0}'
}

js_pkgb_sources_compact() { # $1=PKGBUILD path  $2=limit(optional)
  local nodebin
  nodebin=$(command -v node || command -v nodejs)
  if [ -n "${2:-}" ]; then
    "$nodebin" "$(js_parser_path)" --file "$1" --sources-compact --limit "$2"
  else
    "$nodebin" "$(js_parser_path)" --file "$1" --sources-compact
  fi
}
