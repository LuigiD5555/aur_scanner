#!/usr/bin/env bash
# SPDX-License-Identifier: MIT
# Copyright (c) 2025 José Luis López López Prieto
# Author GitHub: https://github.com/LuigiD5555
# aur_verification_orchestrator.sh — orchestrate verification and optional installation

verify_pkgbuild() { # $1=AUR pkg name
  local pkg="$1"
  local workdir; workdir="$(mktemp -d -t aurver-XXXXXX)"; trap 'rm -rf "${workdir:-}"' EXIT
  local failed=0
  report_init

  local checkout fetch_mode
  IFS=$'\t' read -r checkout fetch_mode < <(aur_checkout_to "$pkg" "$workdir")
  [ -f "$checkout/PKGBUILD" ] || die "PKGBUILD not found at '$checkout/PKGBUILD' (mode=$fetch_mode, pkg=$pkg)."
  local pkgb="$checkout/PKGBUILD"

  case "${fetch_mode:-plain}" in
    plain)
      report_add "item_pkgb_source" "PASS" "source_plain"
      ;;
    snapshot)
      report_add "item_pkgb_source" "PASS" "source_snapshot"
      # Check plain availability separately to avoid false warnings when we simply fell back
      if aur_plain_exists "$pkg" 2>/dev/null; then
        report_add "item_plain_availability" "PASS" "plain_available_ok"
      else
        [ "${STRICT:-0}" = "1" ] && report_add "item_plain_availability" "FAIL" "plain_missing_fail" || report_add "item_plain_availability" "WARN" "plain_missing_warn"
      fi
      ;;
    git)
      report_add "item_pkgb_source" "PASS" "source_git"
      if aur_plain_exists "$pkg" 2>/dev/null; then
        report_add "item_plain_availability" "PASS" "plain_available_ok"
      else
        [ "${STRICT:-0}" = "1" ] && report_add "item_plain_availability" "FAIL" "plain_missing_fail" || report_add "item_plain_availability" "WARN" "plain_missing_warn"
      fi
      ;;
  esac

  if [ "${SHOW_FUNCS:-0}" = "1" ]; then log_info "Showing PKGBUILD function summaries (prepare/build/package)…"; print_func_summaries "$pkgb" | sed 's/^/  /' >&2; fi

  if [ "${QUIET:-0}" != "1" ] && js_parser_available; then
    if [ "${VERBOSE:-0}" = "1" ]; then
      log_info "JS parser summary:"; js_pkgb_parse_summary "$pkgb" | sed 's/^/  /' >&2 || true
      log_info "Sources (resolved):"; js_pkgb_sources_compact "$pkgb" 12 | sed 's/^/  /' >&2 || true
      log_info "Red flags (lines):"; js_pkgb_redflags_lines "$pkgb" | sed 's/^/  /' >&2 || true
    fi
  fi

  # JS signals always first when available (then Bash rules)
  rule_js_signals "$pkgb" "${STRICT:-0}" || failed=1
  rule_vcs_pinning "$pkgb" "${STRICT:-0}" || failed=1
  rule_sources "$pkgb" "${STRICT:-0}" || failed=1
  rule_checksums "$pkgb" "$checkout" "${STRICT:-0}" "${FAST:-0}" || failed=1
  # Always run red flags rule; it uses JS parser when available and falls back to Bash
  rule_red_flags "$pkgb" "${STRICT:-0}" || failed=1
  local mode="full"; [ "${FAST:-0}" = "1" ] && mode="fast"; if [ "${VERIFY_ONLY:-0}" = "1" ] && [ "${DEEP:-0}" != "1" ]; then mode="verify-only"; fi
  [ "$mode" != "full" ] && log_info "Skipping makepkg --verifysource due to mode: $mode" || log_info "Running makepkg --verifysource (no build)…"
  rule_verifysource "$checkout" "$mode" "${STRICT:-0}" || failed=1

  if [ "$VERIFY_ONLY" = "1" ]; then log_info "VERIFY_ONLY=1 -> Verification finished. Not installing."; report_print "verify-only"; return 0; fi
  if [ "$failed" -gt 0 ] || [ "$REPORT_FAILS" -gt 0 ]; then report_print "install"; die "Verification reported failures; aborting installation."; fi
  report_print "install"; log_info "Verification passed. Proceeding to install: $pkg"; require_tools "$YAY_BIN"; "$YAY_BIN" -S "$pkg"
}

install_or_verify() {
  local pkg="$1"
  if [ "$VERIFY_ONLY" = "1" ] && [ "${SHOW_METADATA:-1}" = "1" ] && [ "${QUIET:-0}" != "1" ]; then
    log_info "VERIFY_ONLY=1 -> Showing metadata:"
    if have_cmd "$YAY_BIN"; then
      yay_query_any "$pkg" || true
    else
      log_warn "Skipping repository metadata (yay not available). Use --metadata after installing yay if needed."
    fi
  fi
  verify_pkgbuild "$pkg"
}

aur_checkout_to() { # $1=pkg $2=workdir -> prints "<dir> <mode>" where mode=plain|snapshot|git
  local pkg="$1" workdir="$2" d=""
  if d="$(aur_plain_fetch_plain_files "$pkg" "$workdir" 2>/dev/null)"; then [ -f "$d/PKGBUILD" ] || die "Plain fetch reported success, but PKGBUILD is missing at '$d/PKGBUILD' (pkg=$pkg)."; log_info "Fetched AUR plain PKGBUILD: $pkg"; printf '%s\tplain\n' "$d"; return 0; fi
  if [ "${FAST:-0}" = "1" ]; then die "Plain PKGBUILD unavailable for '$pkg' while FAST=1. Rerun without --fast to allow snapshot/git fallback."; fi
  if d="$(aur_plain_fetch_repo "$pkg" "$workdir" 2>/dev/null)"; then [ -f "$d/PKGBUILD" ] || die "Snapshot extracted, but PKGBUILD is missing at '$d/PKGBUILD' (pkg=$pkg)."; log_info "Fetched AUR snapshot: $pkg"; printf '%s\tsnapshot\n' "$d"; return 0; fi
  if aur_plain_exists "$pkg" 2>/dev/null; then
    log_warn "Plain/snapshot download failed (likely network), but AUR plain URL exists; falling back to git clone: $pkg"
  else
    log_info "Plain/snapshot failed; cloning AUR: $pkg"
  fi
  git clone --depth=1 "https://aur.archlinux.org/${pkg}.git" "$workdir/$pkg" >/dev/null 2>&1 || die "Failed to fetch AUR via plain/snapshot and git clone for '$pkg'."; [ -f "$workdir/$pkg/PKGBUILD" ] || die "PKGBUILD not found after git clone at '$workdir/$pkg/PKGBUILD' (pkg=$pkg)."; printf '%s\tgit\n' "$workdir/$pkg"
}
