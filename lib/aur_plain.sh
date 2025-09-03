#!/usr/bin/env bash
# aur_plain.sh — fetch AUR snapshot or plain files (no git clone required)

aur_plain_snapshot_url() { # $1=pkg
  printf 'https://aur.archlinux.org/cgit/aur.git/snapshot/%s.tar.gz\n' "$1"
}

# Heuristic to ensure a downloaded file is truly a PKGBUILD
is_valid_pkgb() { # $1=file
  local f="$1"
  [ -s "$f" ] || return 1
  # Reject HTML/error pages
  if grep -qiE '<html|<!doctype|<head|<body' "$f" 2>/dev/null; then
    return 1
  fi
  # Expect at least pkgname= somewhere
  grep -qE '^[[:space:]]*pkgname=' "$f"
}

aur_plain_fetch_repo() { # $1=pkg $2=destdir -> prints checkout dir or fails
  local pkg="$1" dest="$2" outdir
  mkdir -p "$dest"
  outdir="$dest/$pkg"
  rm -rf "$outdir" 2>/dev/null || true
  mkdir -p "$outdir"
  local tarball; tarball="$(mktemp -t aur-plain-XXXXXX.tar.gz)"
  if curl -fsSL "$(aur_plain_snapshot_url "$pkg")" -o "$tarball"; then
    # Extract and strip the top-level folder to ensure files land in $outdir
    if tar -xzf "$tarball" --strip-components=1 -C "$outdir" 2>/dev/null; then
      rm -f "$tarball"
      if ! is_valid_pkgb "$outdir/PKGBUILD"; then
        log_warn "Snapshot contains no valid PKGBUILD (might be HTML or missing)."
        return 1
      fi
      printf '%s\n' "$outdir"
      return 0
    fi
  fi
  rm -f "$tarball" 2>/dev/null || true
  return 1
}

aur_plain_fetch_plain_files() { # $1=pkg $2=destdir -> prints dir with PKGBUILD/.SRCINFO
  local pkg="$1" dir="$2/$1"
  mkdir -p "$dir"
  # First, try the dedicated plain endpoint
  if ! curl -fsSL "https://aur.archlinux.org/cgit/aur.git/plain/PKGBUILD?h=$pkg" -o "$dir/PKGBUILD"; then
    return 1
  fi
  if ! is_valid_pkgb "$dir/PKGBUILD"; then
    # Some mirrors/paths might serve the tree page (HTML). Try the ?plain=1 trick.
    log_warn "Downloaded PKGBUILD looked like HTML; retrying with ?plain=1"
    curl -fsSL "https://aur.archlinux.org/cgit/aur.git/tree/PKGBUILD?h=$pkg&plain=1" -o "$dir/PKGBUILD" || return 1
    is_valid_pkgb "$dir/PKGBUILD" || return 1
  fi
  curl -fsSL "https://aur.archlinux.org/cgit/aur.git/plain/.SRCINFO?h=$pkg" -o "$dir/.SRCINFO" || true
  printf '%s\n' "$dir"
}

aur_plain_fetch_any() { # $1=pkg $2=destdir
  # Prefer the smallest transfer first: fetch just PKGBUILD/.SRCINFO as plain text
  aur_plain_fetch_plain_files "$1" "$2" && return 0
  # Fallback to snapshot tarball if plain endpoints fail
  aur_plain_fetch_repo "$1" "$2"
}

aur_plain_rpc_info() { # $1=pkg -> prints JSON
  curl -fsSL "https://aur.archlinux.org/rpc/v5/info/$1"
}
