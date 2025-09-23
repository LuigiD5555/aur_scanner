# SPDX-License-Identifier: MIT
# Copyright (c) 2025 José Luis López López Prieto
# Author GitHub: https://github.com/LuigiD5555
# checksums_rule.sh — enforce checksum policy and optionally auto-rewrite to sha256

# Expectations:
# - has_weak_or_skip: returns 0 if md5/sha1 arrays exist or SKIP is present
# - has_strong_sums : returns 0 if sha256sums/sha512sums arrays are present
# - rewrite_sums_to_sha256 <checkout>: attempts to compute and write sha256 arrays in PKGBUILD
# - report_add <item> <STATUS> <key>
# - log_warn <msg>

rule_checksums() { # $1=pkgb $2=checkout $3=strict $4=fast
  local pkgb="$1" checkout="$2" strict="$3" fast="$4"

  # 1) Weak or SKIP present
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
      report_add "item_checksums" "FAIL" "sum_weak_fail"
      return 1
    fi

    # Non-strict branch: honor fast/verify-only modes
    if [ "$fast" = "1" ]; then
      report_add "item_checksums" "WARN" "sum_autofixed_skipfast"
      return 0
    elif [ "${VERIFY_ONLY:-0}" = "1" ]; then
      report_add "item_checksums" "WARN" "sum_autofixed_skipverifyonly"
      return 0
    else
      if rewrite_sums_to_sha256 "$checkout"; then
        report_add "item_checksums" "PASS" "sum_autofixed_ok"
        return 0
      else
        report_add "item_checksums" "WARN" "sum_autofixed_fail"
        return 0
      fi
    fi
  fi

  # 2) No weak/SKIP, but also no strong sums -> try to fix (unless fast/verify-only)
  if ! sed -n 'p' "$pkgb" | has_strong_sums; then
    log_warn "No strong checksum arrays declared (sha256sums/sha512sums missing)."

    if [ "$strict" = "1" ]; then
      report_add "item_checksums" "FAIL" "sum_missing_strict"
      return 1
    fi

    if [ "$fast" = "1" ]; then
      report_add "item_checksums" "WARN" "sum_missing_fast"
      return 0
    elif [ "${VERIFY_ONLY:-0}" = "1" ]; then
      report_add "item_checksums" "WARN" "sum_autofixed_skipverifyonly"
      return 0
    else
      if rewrite_sums_to_sha256 "$checkout"; then
        report_add "item_checksums" "PASS" "sum_autofixed_ok"
        return 0
      else
        report_add "item_checksums" "WARN" "sum_autofixed_fail"
        return 0
      fi
    fi
  fi

  # 3) Strong sums present and no weak/SKIP found
  report_add "item_checksums" "PASS" "sum_ok"
  return 0
}

# Helper kept here for completeness if you ever decouple it. If you already source this
# from pkgb helpers, feel free to remove this copy.
has_weak_or_skip() {
  # md5/sha1 considered weak; SKIP means not verifying a given source
  grep -Eq '(^|[^a-zA-Z0-9_])(md5sums|sha1sums)[[:space:]]*=|SKIP' || return 1
  return 0
}
