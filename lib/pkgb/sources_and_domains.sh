#!/usr/bin/env bash
# SPDX-License-Identifier: MIT
# Copyright (c) 2025 José Luis López López Prieto <ing.jlllopezp@gmail.com>
# Author GitHub: https://github.com/LuigiD5555
# sources_and_domains.sh — PKGBUILD source listing and domain/HTTPS helpers

_emit_sources_tokens() {
  local block="$1"
  python - "$block" <<'PYTOK'
import re, sys
block = sys.argv[1]
tokens = re.findall(r"'([^']*)'|\"([^\"]*)\"|([^\s]+)", block)
for single, double, bare in tokens:
    token = single or double or bare
    token = token.strip()
    if token:
        print(token)
PYTOK
}

list_sources() {
  local line trimmed collecting=0 buffer=""
  while IFS= read -r line; do
    trimmed="${line%%#*}"
    if (( collecting )); then
      buffer+=$'\n'"${trimmed}"
      if [[ $trimmed == *')'* ]]; then
        collecting=0
        local block="${buffer%%)*}"
        _emit_sources_tokens "$block"
        buffer=""
      fi
      continue
    fi
    if [[ $trimmed =~ ^[[:space:]]*source(\+)?[[:space:]]*=\( ]]; then
      collecting=1
      buffer="${trimmed#*=}"
      buffer="${buffer#*(}"
      if [[ $buffer == *')'* ]]; then
        collecting=0
        local block="${buffer%%)*}"
        _emit_sources_tokens "$block"
        buffer=""
      fi
    fi
  done
}

sources_have_only_https() {
  local entry
  while IFS= read -r entry; do
    entry="${entry##*::}"
    entry="${entry#\"}"
    entry="${entry%\"}"
    entry="${entry#'}"
    entry="${entry%'}"
    entry="${entry#"${entry%%[![:space:]]*}"}"
    entry="${entry%"${entry##*[![:space:]]}"}"
    entry="${entry#git+}"
    [[ -z $entry ]] && continue
    [[ $entry == https://* ]] || return 1
  done
  return 0
}

sources_domains_allowed() {
  local entry domain
  while IFS= read -r entry; do
    entry="${entry##*::}"
    entry="${entry#\"}"
    entry="${entry%\"}"
    entry="${entry#'}"
    entry="${entry%'}"
    entry="${entry#"${entry%%[![:space:]]*}"}"
    entry="${entry%"${entry##*[![:space:]]}"}"
    entry="${entry#git+}"
    [[ $entry =~ ^[a-zA-Z0-9+.-]+:// ]] || continue
    domain="${entry#*://}"
    domain="${domain%%/*}"
    [[ $domain =~ ${ALLOWED_DOMAINS} ]] || return 1
  done
  return 0
}
