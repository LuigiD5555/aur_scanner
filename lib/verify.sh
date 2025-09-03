#!/usr/bin/env bash
# verify.sh — fetch AUR PKGBUILD via snapshot/plain (fallback to git), run checks, optionally install

# Simple end-of-run report (non-expert friendly)
report_init() {
  REPORT_ITEMS=()           # entries: "key|STATUS|message"
  REPORT_FAILS=0
  REPORT_WARNS=0
}

report_add() { # $1=key  $2=STATUS(PASS|WARN|FAIL|SKIP)  $3=message
  REPORT_ITEMS+=("$1|$2|$3")
  case "$2" in
    FAIL) REPORT_FAILS=$((REPORT_FAILS+1));;
    WARN) REPORT_WARNS=$((REPORT_WARNS+1));;
  esac
}

report_print() { # $1=install_mode (install|verify-only)
  printf '\n==== AUR Verification Summary ====\n' >&2
  local line k s m
  for line in "${REPORT_ITEMS[@]}"; do
    k="${line%%|*}"; s="${line#*|}"; s="${s%%|*}"; m="${line##*|}"
    printf ' - %s: %s — %s\n' "$k" "$s" "$m" >&2
  done
  local overall
  if [ "$REPORT_FAILS" -gt 0 ]; then
    overall="FAIL"
  elif [ "$REPORT_WARNS" -gt 0 ]; then
    overall="OK (with warnings)"
  else
    overall="OK"
  fi
  printf ' - Overall: %s\n' "$overall" >&2
  if [ "$1" = "install" ]; then
    if [ "$overall" = "OK" ] || [ "$overall" = "OK (with warnings)" ]; then
      printf ' - Action: Installing with yay\n' >&2
    else
      printf ' - Action: Not installing due to failures\n' >&2
    fi
  else
    printf ' - Action: Verification only (no install)\n' >&2
  fi
  printf '=================================\n\n' >&2
}

aur_checkout_to() { # $1=pkg $2=workdir -> prints "<dir> <mode>" where mode=plain|snapshot|git
  local pkg="$1" workdir="$2" d=""
  # 1) Intentar siempre primero PKGBUILD plano (HTML plain)
  if d="$(aur_plain_fetch_plain_files "$pkg" "$workdir" 2>/dev/null)"; then
    [ -f "$d/PKGBUILD" ] || die "Plain fetch succeeded but PKGBUILD missing."
    log_info "Fetched AUR plain PKGBUILD: $pkg"
    # Emit TAB-delimited pair: <dir>\t<mode>
    printf '%s\tplain\n' "$d"
    return 0
  fi
  # 2) En FAST, cancelar si no hay PKGBUILD plano
  if [ "${FAST:-0}" = "1" ]; then
    die "Plain PKGBUILD not available (FAST mode)."
  fi
  # 3) Normal/Strict: intentar snapshot
  if d="$(aur_plain_fetch_repo "$pkg" "$workdir" 2>/dev/null)"; then
    [ -f "$d/PKGBUILD" ] || die "Snapshot extracted but PKGBUILD missing."
    log_info "Fetched AUR snapshot: $pkg"
    printf '%s\tsnapshot\n' "$d"
    return 0
  fi
  # 4) Fallback final a git clone
  log_info "Plain/snapshot failed; cloning AUR: $pkg"
  git clone --depth=1 "https://aur.archlinux.org/${pkg}.git" "$workdir/$pkg" >/dev/null 2>&1 \
    || die "Failed to fetch AUR via plain/snapshot and git clone."
  [ -f "$workdir/$pkg/PKGBUILD" ] || die "PKGBUILD not found after git clone."
  printf '%s\tgit\n' "$workdir/$pkg"
}

verify_pkgbuild() { # $1=AUR pkg name
  local pkg="$1"
  local workdir; workdir="$(mktemp -d -t aurver-XXXXXX)"
  # Use safe expansion so set -u doesn't error after local goes out of scope
  trap 'rm -rf "${workdir:-}"' EXIT
  local failed=0
  report_init

  local checkout fetch_mode
  # Use a tab-delimited pair to avoid interference with global IFS changes
  IFS=$'\t' read -r checkout fetch_mode < <(aur_checkout_to "$pkg" "$workdir")
  [ -f "$checkout/PKGBUILD" ] || die "PKGBUILD not found."
  local pkgb="$checkout/PKGBUILD"

  case "${fetch_mode:-plain}" in
    plain)
      report_add "item_pkgb_source" "PASS" "source_plain" ;;
    snapshot)
      report_add "item_pkgb_source" "PASS" "source_snapshot"
      if [ "${STRICT:-0}" = "1" ]; then
        report_add "item_plain_availability" "FAIL" "plain_missing_fail"
      else
        report_add "item_plain_availability" "WARN" "plain_missing_warn"
      fi
      ;;
    git)
      report_add "item_pkgb_source" "PASS" "source_git"
      if [ "${STRICT:-0}" = "1" ]; then
        report_add "item_plain_availability" "FAIL" "plain_missing_fail"
      else
        report_add "item_plain_availability" "WARN" "plain_missing_warn"
      fi
      ;;
  esac

  log_info "Showing PKGBUILD function summaries (prepare/build/package)…"
  print_func_summaries "$pkgb" | sed 's/^/  /' >&2

  # Optional: quick JS summary (if Node parser is available)
  if js_parser_available; then
    log_info "JS parser summary:"; js_pkgb_parse_summary "$pkgb" | sed 's/^/  /' >&2 || true
    # Connect parser signals into the report
    local js_unpinned=0 js_nonhttps=0 js_redflags=0 js_sources=0
    while IFS='=' read -r k v; do
      case "$k" in
        unpinnedGit) js_unpinned="$v";;
        nonHttps)    js_nonhttps="$v";;
        redFlags)    js_redflags="$v";;
        sources)     js_sources="$v";;
      esac
    done < <(js_pkgb_signals "$pkgb" 2>/dev/null || true)
    # Sources info (informativo)
    report_add "item_js_sources" "PASS" "sources_${js_sources}"
    # Unpinned git
    if [ "$js_unpinned" -gt 0 ]; then
      if [ "${STRICT:-0}" = "1" ]; then
        report_add "item_js_git_pinning" "FAIL" "js_git_unpinned_fail"
      else
        report_add "item_js_git_pinning" "WARN" "js_git_unpinned_warn"
      fi
    else
      report_add "item_js_git_pinning" "PASS" "js_git_pinned_ok"
    fi
    # Non-HTTPS
    if [ "$js_nonhttps" -gt 0 ]; then
      if [ "${STRICT:-0}" = "1" ]; then
        report_add "item_js_https" "FAIL" "js_https_fail"
      else
        report_add "item_js_https" "WARN" "js_https_warn"
      fi
    else
      report_add "item_js_https" "PASS" "js_https_ok"
    fi
    # Mostrar lista compacta de fuentes resueltas (limitada)
    log_info "Sources (resolved):"
    js_pkgb_sources_compact "$pkgb" 12 | sed 's/^/  /' >&2 || true
    # Red flags: handled centrally in rule_red_flags (JS-aware). No extra item here.
  fi

  # VCS pinning
  rule_vcs_pinning "$pkgb" "${STRICT:-0}" || failed=1

  # Source URL and domains
  rule_sources "$pkgb" "${STRICT:-0}" || failed=1

  # Checksums
  rule_checksums "$pkgb" "$checkout" "${STRICT:-0}" "${FAST:-0}" || failed=1

  # Red flags
  local flags; flags="$(scan_red_flags "$pkgb")"; [ -n "$flags" ] && { log_warn "Potential red flags found in PKGBUILD:"; printf '%s\n' "$flags" | sed 's/^/  /' >&2; }
  rule_red_flags "$pkgb" "${STRICT:-0}" || failed=1

  # verifysource
  local mode="full"
  if [ "${FAST:-0}" = "1" ]; then mode="fast"; fi
  if [ "${VERIFY_ONLY:-0}" = "1" ] && [ "${DEEP:-0}" != "1" ]; then mode="verify-only"; fi
  [ "$mode" != "full" ] && log_info "Skipping makepkg --verifysource due to mode: $mode" || log_info "Running makepkg --verifysource (no build)…"
  rule_verifysource "$checkout" "$mode" "${STRICT:-0}" || failed=1

  if [ "$VERIFY_ONLY" = "1" ]; then
    log_info "VERIFY_ONLY=1 -> Verification finished. Not installing."
    report_print "verify-only"
    return 0
  fi

  if [ "$failed" -gt 0 ] || [ "$REPORT_FAILS" -gt 0 ]; then
    report_print "install"
    die "Verification reported failures; aborting installation."
  fi

  report_print "install"
  log_info "Verification passed. Proceeding to install: $pkg"
  "$YAY_BIN" -S "$pkg"
}

install_or_verify() {
  local pkg="$1"
  if [ "$VERIFY_ONLY" = "1" ]; then
    log_info "VERIFY_ONLY=1 -> Showing metadata:"
    yay_query_any "$pkg" || true
  fi
  verify_pkgbuild "$pkg"
}
