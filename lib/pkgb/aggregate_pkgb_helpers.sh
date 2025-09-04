#!/usr/bin/env bash
# License: CC BY-NC-SA 4.0 (https://creativecommons.org/licenses/by-nc-sa/4.0/)
# Copyright (c) 2025 José Luis López López Prieto
# aggregate_pkgb_helpers.sh — aggregates PKGBUILD helper functions

SCRIPT_DIR=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)
ALLOWED_DOMAINS="${ALLOWED_DOMAINS:-github.com|codeload.github.com|objects.githubusercontent.com|gitlab.com}"

source "$SCRIPT_DIR/sources_and_domains.sh"
source "$SCRIPT_DIR/checksums_policy.sh"
source "$SCRIPT_DIR/redflags_scan.sh"
source "$SCRIPT_DIR/functions_summary.sh"

# keep pkgb_check_vcs_pinning from original pkgb.sh
pkgb_check_vcs_pinning() { # $1=PKGBUILD
  local pkgb="$1" unpinned=0
  local sources
  sources="$(sed -n 's/^[[:space:]]*source[[:space:]]*=[[:space:]]*(\(.*\))/\1/p' "$pkgb" \
            | tr ' ' '\n' | tr -d "\"'" | sed 's/[()]//g')"
  while IFS= read -r s; do
    [ -z "$s" ] && continue
    case "$s" in *::*) s="${s#*::}";; esac
    case "$s" in
      git+http*|git+https*)
        if ! printf '%s' "$s" | grep -Eq '#(commit|tag)='; then
          log_warn "Unpinned VCS source: $s (add #commit= or #tag= per VCS guidelines)"
          unpinned=1
        fi
        ;;
    esac
  done <<EOF
$sources
EOF
  return $unpinned
}
