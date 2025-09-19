#!/usr/bin/env bash
# SPDX-License-Identifier: MIT
# Copyright (c) 2025 José Luis López López Prieto <ing.jlllopezp@gmail.com>
# Author GitHub: https://github.com/LuigiD5555
# checksums_rule.sh — enforce checksum policy and optional rewrite

rule_checksums() { # $1=pkgb $2=checkout $3=strict $4=fast
  local pkgb="$1" checkout="$2" strict="$3" fast="$4"
  if sed -n 'p' "$pkgb" | has_weak_or_skip; then
    if [ "${VERBOSE:-0}" = "1" ]; then
      log_warn "Checksum arrays (marking weak or SKIP entries):"
      awk '
        /^[[:space:]]*(md5sums|sha1sums|sha256sums|sha512sums)=/ {print "  " NR ":" $0; next}
        /SKIP/ {print "  [SKIP] " NR ":" $0}
      ' "$pkgb" >&2 || true
    else
      log_warn "Weak or skipped checksums found (lines):"
      awk '/^[[:space:]]*(md5sums|sha1sums)=/ || /SKIP/ {printf "  %d:%s\n", NR, $0}' "$pkgb" >&2 || true
    fi
    if [ "$strict" = "1" ]; then
      report_add "item_checksums" "FAIL" "sum_weak_fail"; return 1
    else
      if [ "$fast" = "1" ]; then
        report_add "item_checksums" "WARN" "sum_autofixed_skipfast"; return 0
      elif [ "${VERIFY_ONLY:-0}" = "1" ]; then
        report_add "item_checksums" "WARN" "sum_autofixed_skipverifyonly"; return 0
      else
        if rewrite_sums_to_sha256 "$checkout"; then
          report_add "item_checksums" "PASS" "sum_autofixed_ok"; return 0
        else
          report_add "item_checksums" "WARN" "sum_autofixed_fail"; return 0
        fi
      fi
    fi
  elif ! sed -n 'p' "$pkgb" | has_strong_sums; then
    log_warn "No strong checksum arrays declared (sha256sums/sha512sums missing)."
    if [ "$strict" = "1" ]; then
      report_add "item_checksums" "FAIL" "sum_missing_strict"; return 1
    else
      if [ "$fast" = "1" ]; then
        report_add "item_checksums" "WARN" "sum_missing_fast"; return 0
      elif [ "${VERIFY_ONLY:-0}" = "1" ]; then
        report_add "item_checksums" "WARN" "sum_autofixed_skipverifyonly"; return 0
      else
        if rewrite_sums_to_sha256 "$checkout"; then
          report_add "item_checksums" "PASS" "sum_autofixed_ok"; return 0
        else
          report_add "item_checksums" "WARN" "sum_autofixed_fail"; return 0
        fi
      fi
    fi
  fi
}
