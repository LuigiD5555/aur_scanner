#!/usr/bin/env bash
# verify_rules.sh — Small, focused verification rules that add report entries

rule_vcs_pinning() { # $1=pkgb $2=strict -> sets report items
  local pkgb="$1" strict="$2"
  if ! pkgb_check_vcs_pinning "$pkgb"; then
    if [ "$strict" = "1" ]; then
      report_add "item_vcs_pinning" "FAIL" "vcs_unpinned_fail"; return 1
    else
      report_add "item_vcs_pinning" "WARN" "vcs_unpinned_warn"; return 0
    fi
  else
    report_add "item_vcs_pinning" "PASS" "vcs_pinned_ok"; return 0
  fi
}

rule_sources() { # $1=pkgb $2=strict -> HTTPS + domains
  local pkgb="$1" strict="$2" sources
  sources="$(sed -n 'p' "$pkgb" | list_sources || true)"
  [ -z "$sources" ] && return 0

  if ! printf '%s\n' "$sources" | sources_have_only_https; then
    # Print only offending lines to help debugging, without dumping the full PKGBUILD
    log_warn "Non-HTTPS sources detected:"; printf '%s\n' "$sources" | awk '!/^https:/' | sed 's/^/  /' >&2
    if [ "$strict" = "1" ]; then
      report_add "item_source_urls" "FAIL" "urls_https_fail"; return 1
    else
      report_add "item_source_urls" "WARN" "urls_https_warn"
    fi
  else
    report_add "item_source_urls" "PASS" "urls_https_ok"
  fi

  # Domains: ensure ALL sources are allowed
  if ! printf '%s\n' "$sources" | sources_domains_allowed; then
    log_warn "Sources from non-allowed domains:"; printf '%s\n' "$sources" | grep -Ev "$ALLOWED_DOMAINS" | sed 's/^/  /' >&2 || true
    if [ "$strict" = "1" ]; then
      report_add "item_allowed_domains" "FAIL" "domains_fail"; return 1
    else
      report_add "item_allowed_domains" "WARN" "domains_warn"
    fi
  else
    report_add "item_allowed_domains" "PASS" "domains_ok"
  fi
}

rule_checksums() { # $1=pkgb $2=checkout $3=strict $4=fast
  local pkgb="$1" checkout="$2" strict="$3" fast="$4"
  if sed -n 'p' "$pkgb" | has_weak_or_skip; then
    if [ "$strict" = "1" ]; then
      report_add "item_checksums" "FAIL" "sum_weak_fail"; return 1
    else
      if [ "$fast" = "1" ]; then
        report_add "item_checksums" "WARN" "sum_autofixed_skipfast"; return 0
      else
        if rewrite_sums_to_sha256 "$checkout"; then
          report_add "item_checksums" "PASS" "sum_autofixed_ok"; return 0
        else
          report_add "item_checksums" "WARN" "sum_autofixed_fail"; return 0
        fi
      fi
    fi
  elif ! sed -n 'p' "$pkgb" | has_strong_sums; then
    if [ "$strict" = "1" ]; then
      report_add "item_checksums" "FAIL" "sum_missing_strict"; return 1
    else
      if [ "$fast" = "1" ]; then
        report_add "item_checksums" "WARN" "sum_missing_fast"; return 0
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

rule_red_flags() { # $1=pkgb $2=strict
  local pkgb="$1" strict="$2" flags="" count=0
  # Prefer JS parser if disponible para obtener líneas exactas
  if js_parser_available; then
    count=$(js_pkgb_redflags_count "$pkgb" 2>/dev/null || echo 0)
    if [ "$count" -gt 0 ]; then
      log_warn "Potential red flags found in PKGBUILD (JS parser):"
      js_pkgb_redflags_lines "$pkgb" | sed 's/^/  /' >&2
      if [ "$strict" = "1" ]; then
        report_add "item_red_flags" "FAIL" "redflags_fail"; return 1
      else
        report_add "item_red_flags" "WARN" "redflags_warn"; return 0
      fi
    else
      report_add "item_red_flags" "PASS" "redflags_ok"; return 0
    fi
  fi
  # Fallback grep-based
  flags="$(scan_red_flags "$pkgb")"
  if [ -n "$flags" ]; then
    log_warn "Potential red flags found in PKGBUILD:"; printf '%s\n' "$flags" | sed 's/^/  /' >&2
    if [ "$strict" = "1" ]; then
      report_add "item_red_flags" "FAIL" "redflags_fail"; return 1
    else
      report_add "item_red_flags" "WARN" "redflags_warn"; return 0
    fi
  else
    report_add "item_red_flags" "PASS" "redflags_ok"; return 0
  fi
}

rule_verifysource() { # $1=checkout $2=mode (fast|verify-only|full) $3=strict
  local checkout="$1" mode="$2" strict="$3"
  case "$mode" in
    verify-only)
      report_add "item_makepkg_verifysource" "SKIP" "verifysource_skip_verifyonly"; return 0;;
    fast)
      report_add "item_makepkg_verifysource" "SKIP" "verifysource_skip_fast"; return 0;;
    full)
      if (cd "$checkout" && makepkg --noconfirm --nodeps --verifysource); then
        report_add "item_makepkg_verifysource" "PASS" "verifysource_ok"; return 0
      else
        if [ "$strict" = "1" ]; then
          report_add "item_makepkg_verifysource" "FAIL" "verifysource_fail_strict"; return 1
        else
          report_add "item_makepkg_verifysource" "WARN" "verifysource_fail"; return 0
        fi
      fi
      ;;
  esac
}
