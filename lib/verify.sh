#!/usr/bin/env bash
# verify.sh — clone AUR PKGBUILD, run checks and optionally install

verify_pkgbuild() { # $1=AUR pkg name
  local pkg="$1"
  local workdir; workdir="$(mktemp -d -t aurver-XXXXXX)"
  trap 'rm -rf "$workdir"' EXIT

  log_info "Cloning AUR: $pkg"
  git clone --depth=1 "https://aur.archlinux.org/${pkg}.git" "$workdir/$pkg" >/dev/null 2>&1 || die "Failed to clone AUR repo."

  [ -f "$workdir/$pkg/PKGBUILD" ] || die "PKGBUILD not found."
  local pkgb="$workdir/$pkg/PKGBUILD"

  log_info "Showing PKGBUILD function summaries (prepare/build/package)…"
  print_func_summaries "$pkgb" | sed 's/^/  /' >&2

  local sources
  sources="$(sed -n 'p' "$pkgb" | list_sources || true)"

  if [ -n "$sources" ]; then
    if ! printf '%s\n' "$sources" | sources_have_only_https; then
      [ "$STRICT" = "1" ] && die "HTTP or non-HTTPS sources are forbidden in STRICT."
      log_warn "Non-HTTPS sources detected (allowed in normal mode, but discouraged)."
    fi
    if ! printf '%s\n' "$sources" | grep -E "$ALLOWED_DOMAINS" >/dev/null; then
      [ "$STRICT" = "1" ] && die "Source domains not in whitelist."
      log_warn "Source domains outside whitelist (normal mode: allowed but warned)."
    fi
  fi

  if sed -n 'p' "$pkgb" | has_weak_or_skip; then
    if [ "$STRICT" = "1" ]; then
      die "Weak sums (md5/sha1) or SKIP detected in STRICT mode."
    else
      if [ "$FAST" = "1" ]; then
        log_warn "FAST=1: skipping downloads; cannot auto-upgrade sums."
      else
        log_info "Auto-upgrading checksums to sha256…"
        rewrite_sums_to_sha256 "$workdir/$pkg" || log_warn "Failed to rewrite sums; continuing."
      fi
    fi
  elif ! sed -n 'p' "$pkgb" | has_strong_sums; then
    if [ "$STRICT" = "1" ]; then
      die "No strong sums (sha256/sha512) declared."
    else
      if [ "$FAST" = "1" ]; then
        log_warn "FAST=1: skipping downloads; cannot add sha256sums."
      else
        log_info "No strong sums declared; attempting to generate sha256sums…"
        rewrite_sums_to_sha256 "$workdir/$pkg" || log_warn "Failed to add sha256sums."
      fi
    fi
  fi

  local flags; flags="$(scan_red_flags "$pkgb")"
  if [ -n "$flags" ]; then
    log_warn "Potential red flags found in PKGBUILD:"
    printf '%s\n' "$flags" | sed 's/^/  /' >&2
    [ "$STRICT" = "1" ] && die "Aborting due to red flags in STRICT."
  fi

  if [ "$FAST" = "1" ]; then
    log_info "FAST=1: Skipping makepkg --verifysource."
  else
    log_info "Running makepkg --verifysource (no build)…"
    if ! (cd "$workdir/$pkg" && makepkg --noconfirm --nodeps --verifysource); then
      [ "$STRICT" = "1" ] && die "makepkg --verifysource failed in STRICT mode."
      log_warn "makepkg --verifysource failed (normal mode: warn)."
    fi
  fi

  if [ "$VERIFY_ONLY" = "1" ]; then
    log_info "VERIFY_ONLY=1 -> Verification finished. Not installing."
    return 0
  fi

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

