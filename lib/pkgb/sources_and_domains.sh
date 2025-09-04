#!/usr/bin/env bash
# License: CC BY-NC-SA 4.0 (https://creativecommons.org/licenses/by-nc-sa/4.0/)
# Copyright (c) 2025 José Luis López López Prieto
# sources_and_domains.sh — PKGBUILD source listing and domain/HTTPS helpers

list_sources() {
  sed -n "s/^[[:space:]]*source[[:space:]]*=[[:space:]]*(\(.*\))/\1/p" \
    | tr ' ' '\n' | tr -d "\"'" \
    | sed "s/[()']//g" | grep -E '^(https?|git|ftp)://|::https?://|::git://'
}

sources_have_only_https() { awk '!/^https:\/\// {bad=1} END{exit bad}'; }
sources_domains_allowed() { grep -Ev "$ALLOWED_DOMAINS" >/dev/null && return 1 || return 0; }
