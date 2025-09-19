#!/usr/bin/env bash
# SPDX-License-Identifier: MIT
# Copyright (c) 2025 José Luis López López Prieto <ing.jlllopezp@gmail.com>
# Author GitHub: https://github.com/LuigiD5555
# checksums_policy.sh — checksum detection and rewrite helpers

has_strong_sums() { grep -Eq '^[[:space:]]*(sha256sums|sha512sums)='; }
has_weak_or_skip() { grep -Eq '^[[:space:]]*(md5sums|sha1sums)=' || grep -Eq '(^|[[:space:]])SKIP([[:space:]]|")'; }

rewrite_sums_to_sha256() { # dir with PKGBUILD
  local dir="$1"
  (cd "$dir"
    makepkg --noconfirm --nodeps --noprepare --noextract -g >/dev/null 2>&1 || true
    local gen; gen="$(makepkg -g 2>/dev/null || true)"
    if ! printf '%s\n' "$gen" | grep -q '^sha256sums='; then
      log_warn "makepkg -g did not produce sha256sums; skipping rewrite."
      return 1
    fi
    awk -v repl="$(printf '%s' "$gen" | sed 's/[&/\]/\\&/g')" '
      BEGIN{printed=0}
      /^[[:space:]]*(md5sums|sha1sums|sha256sums|sha512sums)=/ {
        if (!printed) { print repl; printed=1 }
        next
      }
      { print }
    ' PKGBUILD > PKGBUILD.new && mv PKGBUILD.new PKGBUILD
  )
}
