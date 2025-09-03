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
  local pkg="$1" dir="$2/$1" cache_dir ttl now
  mkdir -p "$dir"

  # Simple cache to avoid repeated network calls
  cache_dir="${AUR_CACHE_DIR:-/tmp/aur-plain-cache}"
  ttl="${AUR_CACHE_TTL_SEC:-3600}" # 1h default
  now="$(date +%s)"
  mkdir -p "$cache_dir"
  if [ -f "$cache_dir/$pkg.PKGBUILD" ]; then
    local mtime
    mtime="$(stat -c %Y "$cache_dir/$pkg.PKGBUILD" 2>/dev/null || echo 0)"
    if [ $((now - mtime)) -lt "$ttl" ]; then
      cp "$cache_dir/$pkg.PKGBUILD" "$dir/PKGBUILD" 2>/dev/null || true
      [ -s "$dir/PKGBUILD" ] && { printf '%s\n' "$dir"; return 0; }
    fi
  fi

  # Common curl opts
  local CURL_OPTS
  CURL_OPTS=(--fail --silent --show-error --location --compressed --connect-timeout 5 --max-time 20)

  # First, try the dedicated plain endpoint
  if ! curl "${CURL_OPTS[@]}" "https://aur.archlinux.org/cgit/aur.git/plain/PKGBUILD?h=$pkg" -o "$dir/PKGBUILD"; then
    return 1
  fi
  if ! is_valid_pkgb "$dir/PKGBUILD"; then
    # Some mirrors/paths might serve the tree page (HTML). Try the ?plain=1 trick.
    log_warn "Downloaded PKGBUILD looked like HTML; retrying with ?plain=1"
    curl "${CURL_OPTS[@]}" "https://aur.archlinux.org/cgit/aur.git/tree/PKGBUILD?h=$pkg&plain=1" -o "$dir/PKGBUILD" || return 1
    is_valid_pkgb "$dir/PKGBUILD" || return 1
  fi
  # Save to cache on success (best-effort)
  cp "$dir/PKGBUILD" "$cache_dir/$pkg.PKGBUILD" 2>/dev/null || true
  # .SRCINFO is optional; download only if VERBOSE=1 or STRICT=1
  if [ "${VERBOSE:-0}" = "1" ] || [ "${STRICT:-0}" = "1" ]; then
    curl "${CURL_OPTS[@]}" "https://aur.archlinux.org/cgit/aur.git/plain/.SRCINFO?h=$pkg" -o "$dir/.SRCINFO" || true
  fi
  printf '%s\n' "$dir"
}

aur_plain_fetch_any() { # $1=pkg $2=destdir
  # Prefer the smallest transfer first: fetch just PKGBUILD/.SRCINFO as plain text
  aur_plain_fetch_plain_files "$1" "$2" && return 0
  # Fallback to snapshot tarball if plain endpoints fail
  aur_plain_fetch_repo "$1" "$2"
}

aur_plain_rpc_info() { # $1=pkg -> prints JSON (cached, with timeouts)
  local pkg="$1" cache_dir ttl now
  cache_dir="${AUR_RPC_CACHE_DIR:-/tmp/aur-rpc-cache}"
  ttl="${AUR_RPC_CACHE_TTL_SEC:-600}"
  now="$(date +%s)"
  mkdir -p "$cache_dir"
  if [ -f "$cache_dir/$pkg.json" ]; then
    local mtime
    mtime="$(stat -c %Y "$cache_dir/$pkg.json" 2>/dev/null || echo 0)"
    if [ $((now - mtime)) -lt "$ttl" ]; then
      cat "$cache_dir/$pkg.json" && return 0
    fi
  fi
  local CURL_OPTS
  CURL_OPTS=(--fail --silent --show-error --location --compressed --connect-timeout 3 --max-time 6)
  if curl "${CURL_OPTS[@]}" "https://aur.archlinux.org/rpc/v5/info/$pkg" -o "$cache_dir/$pkg.json"; then
    cat "$cache_dir/$pkg.json"
  else
    # Best-effort: print stale cache if exists
    [ -f "$cache_dir/$pkg.json" ] && cat "$cache_dir/$pkg.json"
  fi
}

# aur_plain_rpc_search — fast AUR name search (cached)
# Usage: aur_plain_rpc_search <term>
# Prints candidate package names (one per line)
aur_plain_rpc_search() { # $1=term
  local term="$1" cache_dir ttl now
  cache_dir="${AUR_RPC_CACHE_DIR:-/tmp/aur-rpc-cache}"
  ttl="${AUR_RPC_CACHE_TTL_SEC:-600}"
  now="$(date +%s)"
  mkdir -p "$cache_dir"
  local f="$cache_dir/search_${term}.json"
  if [ -f "$f" ]; then
    local mtime; mtime="$(stat -c %Y "$f" 2>/dev/null || echo 0)"
    if [ $((now - mtime)) -lt "$ttl" ]; then
      :
    else
      rm -f "$f" 2>/dev/null || true
    fi
  fi
  local CURL_OPTS
  CURL_OPTS=(--fail --silent --show-error --location --compressed --connect-timeout 3 --max-time 6)
  [ -f "$f" ] || curl "${CURL_OPTS[@]}" "https://aur.archlinux.org/rpc/v5/search/$term" -o "$f" 2>/dev/null || true
  [ -s "$f" ] || return 1
  grep -o '"Name":"[^"]\+"' "$f" | sed 's/.*:"//;s/"$//' | sort -u
}
