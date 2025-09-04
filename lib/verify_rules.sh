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
    if [ "${VERBOSE:-0}" = "1" ]; then
      log_warn "All sources (marking non-HTTPS):"
      printf '%s\n' "$sources" | awk '{p=$0; if ($0 !~ /^https:\/\//) p="[non-https] " p; print "  " p}' >&2
    else
      # Print only offending lines to help debugging, without dumping the full PKGBUILD
      log_warn "Non-HTTPS sources detected:"; printf '%s\n' "$sources" | awk '!/^https:/' | sed 's/^/  /' >&2
    fi
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
    if [ "${VERBOSE:-0}" = "1" ]; then
      log_warn "All sources (marking non-allowed domains):"
      printf '%s\n' "$sources" | awk -v re="$ALLOWED_DOMAINS" 'BEGIN{IGNORECASE=0} {ok=($0 ~ re); p=$0; if (!ok) p="[non-allowed] " p; print "  " p}' >&2
    else
      log_warn "Sources from non-allowed domains:"; printf '%s\n' "$sources" | grep -Ev "$ALLOWED_DOMAINS" | sed 's/^/  /' >&2 || true
    fi
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
    if [ "${VERBOSE:-0}" = "1" ]; then
      log_warn "Checksum arrays (marking weak or SKIP entries):"
      awk '
        /^[[:space:]]*(md5sums|sha1sums|sha256sums|sha512sums)=/ {print "  " NR ":" $0; next}
        /SKIP/ {print "  [SKIP] " NR ":" $0}
      ' "$pkgb" >&2 || true
    else
      # Show only the offending lines (weak sums or SKIP entries)
      log_warn "Weak or skipped checksums found (lines):"
      awk '/^[[:space:]]*(md5sums|sha1sums)=/ || /SKIP/ {printf "  %d:%s\n", NR, $0}' "$pkgb" >&2 || true
    fi
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
    # No strong sums present at all — nothing to snippet, but clarify in logs
    log_warn "No strong checksum arrays declared (sha256sums/sha512sums missing)."
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
  # Prefer JS parser if disponible para obtener líneas exactas (skip under QUIET for speed)
  if [ "${QUIET:-0}" != "1" ] && js_parser_available; then
    count=$(js_pkgb_redflags_count "$pkgb" 2>/dev/null || echo 0)
    if [ "$count" -gt 0 ]; then
      # Detect common benign pattern: eval used for arch-based variable indirection
      local lines benign=1
      lines="$(js_pkgb_redflags_lines "$pkgb" 2>/dev/null || true)"
      if [ -n "$lines" ]; then
        while IFS= read -r ln; do
          # Strip "<line>\t<content>" into just content
          local content
          content="${ln#*\t}"
          # Detect pattern: $(eval echo "${_FOO_$CARCH}")
          if ! printf '%s' "$content" | grep -Eq '\$\(eval[[:space:]]+echo[[:space:]]+"\$\{_[A-Za-z0-9_]+_\$CARCH\}"\)'; then
            benign=0; break
          fi
        done <<EOF
$lines
EOF
      fi
      if [ "$benign" = "1" ]; then
        log_warn "Red flags: eval used to select file by CPU architecture (low risk):"
        printf '%s\n' "$lines" | sed 's/^/  /' >&2
        if [ "$strict" = "1" ]; then
          report_add "item_red_flags" "FAIL" "redflags_fail"; return 1
        else
          report_add "item_red_flags" "WARN" "redflags_warn_arch_eval"; return 0
        fi
      else
        log_warn "Potential red flags found in PKGBUILD (JS parser):"
        printf '%s\n' "$lines" | sed 's/^/  /' >&2
        if [ "$strict" = "1" ]; then
          report_add "item_red_flags" "FAIL" "redflags_fail"; return 1
        else
          report_add "item_red_flags" "WARN" "redflags_warn"; return 0
        fi
      fi
    else
      report_add "item_red_flags" "PASS" "redflags_ok"; return 0
    fi
  fi
  # Fallback grep-based
  flags="$(scan_red_flags "$pkgb")"
  if [ -n "$flags" ]; then
    # Try to identify the benign eval-arch pattern in fallback mode
    local eval_lines total_eval benign_fallback=0
    total_eval=$(grep -En 'eval' "$pkgb" | wc -l | tr -d ' ')
    eval_lines=$(grep -En '\$\(eval[[:space:]]+echo[[:space:]]+"\$\{_[A-Za-z0-9_]+_\$CARCH\}"\)' "$pkgb" | wc -l | tr -d ' ')
    if [ "$total_eval" -gt 0 ] && [ "$total_eval" -eq "$eval_lines" ]; then
      benign_fallback=1
    fi
    if [ "$benign_fallback" = "1" ]; then
      log_warn "Red flags: eval used to select file by CPU architecture (low risk):"
      printf '%s\n' "$flags" | sed 's/^/  /' >&2
      if [ "$strict" = "1" ]; then
        report_add "item_red_flags" "FAIL" "redflags_fail"; return 1
      else
        report_add "item_red_flags" "WARN" "redflags_warn_arch_eval"; return 0
      fi
    else
      log_warn "Potential red flags found in PKGBUILD:"; printf '%s\n' "$flags" | sed 's/^/  /' >&2
      if [ "$strict" = "1" ]; then
        report_add "item_red_flags" "FAIL" "redflags_fail"; return 1
      else
        report_add "item_red_flags" "WARN" "redflags_warn"; return 0
      fi
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
