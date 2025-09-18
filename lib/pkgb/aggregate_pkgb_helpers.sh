#!/usr/bin/env bash
# SPDX-License-Identifier: MIT
# Copyright (c) 2025 José Luis López López Prieto
# Author GitHub: https://github.com/LuigiD5555
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
  while IFS= read -r source_entry; do
    [ -z "$source_entry" ] && continue
    local url="$source_entry"
    case "$url" in *::*) url="${url#*::}";; esac
    url="${url#\"}"
    url="${url%\"}"
    url="${url#'}"
    url="${url%'}"
    url="${url#${url%%[![:space:]]*}}"
    url="${url%${url##*[![:space:]]}}"
    case "$url" in
      git+http*|git+https*|git+ssh*|git+git*)
        if [[ "$url" != *#commit=* && "$url" != *#tag=* ]]; then
          log_warn "Unpinned VCS source: $url (add #commit= or #tag= per VCS guidelines)"
          unpinned=1
        fi
        ;;
    esac
  done < <(sed -n 'p' "$pkgb" | list_sources)
  return $unpinned
}
