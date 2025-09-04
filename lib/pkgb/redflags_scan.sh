#!/usr/bin/env bash
# License: CC BY-NC-SA 4.0 (https://creativecommons.org/licenses/by-nc-sa/4.0/)
# Copyright (c) 2025 José Luis López López Prieto
# redflags_scan.sh — scan PKGBUILD for red flag patterns using shared list

scan_red_flags() { # PKGBUILD path
  local pkgb="$1" script_dir rules
  script_dir=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)
  rules="$script_dir/../rules/redflags.list"
  if [ -f "$rules" ]; then
    local tmp; tmp="$(mktemp -t redflags-XXXXXX.regex)"
    awk 'BEGIN{IGNORECASE=0} /^[[:space:]]*#/ {next} NF>0 {print}' "$rules" > "$tmp"
    grep -Eni -E -f "$tmp" "$pkgb" || true
    rm -f "$tmp" >/dev/null 2>&1 || true
  else
    grep -Eni \
      -e 'curl[[:space:]]*\|[[:space:]]*(sh|bash)' \
      -e 'wget[[:space:]]*\|[[:space:]]*(sh|bash)' \
      -e '\beval\b[[:space:]]' \
      -e 'base64[[:space:]]*-d.*\|' \
      -e 'openssl[[:space:]]+enc' \
      -e '/dev/tcp' \
      -e 'rm[[:space:]]*-rf[[:space:]]+(/|\$)' \
      -e '\buseradd\b[[:space:]]' \
      -e '\bsystemctl\b[[:space:]]+(enable|start)' \
      -e '\bsetcap\b[[:space:]]' \
      -e 'chmod[[:space:]][47][0-9]{3}' \
      -e '\bpython\b[[:space:]]+-c' \
      -e '\bperl\b[[:space:]]+-e' \
      -e '\bruby\b[[:space:]]+-e' \
      -e '\bnode\b[[:space:]]+-e' \
      -e '\$\(.*curl.*\)' \
      -e 'dd[[:space:]]+if=.*of=/' \
      -e '\bmount\b[[:space:]]+' \
      -e '\bumount\b[[:space:]]+' \
      -e '\bsu\b[[:space:]]+-c' \
      -e '\bsudo\b[[:space:]]+' \
      -e '\bpkexec\b[[:space:]]+' \
      "$pkgb" || true
  fi
}
