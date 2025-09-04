#!/usr/bin/env bash
# License: CC BY-NC-SA 4.0 (https://creativecommons.org/licenses/by-nc-sa/4.0/)
# Copyright (c) 2025 José Luis López López Prieto
# fetch_plain_and_snapshot.sh — AUR plain/snapshot fetchers and RPC helpers

aur_plain_snapshot_url() { # $1=pkg
  printf 'https://aur.archlinux.org/cgit/aur.git/snapshot/%s.tar.gz\n' "$1"
}

is_valid_pkgb() { # $1=file; heuristic for PKGBUILD content
  local f="$1"
  [ -s "$f" ] || return 1
  if grep -qiE '<html|<!doctype|<head|<body' "$f" 2>/dev/null; then return 1; fi
  grep -qE '^[[:space:]]*pkgname=' "$f"
}

# Snapshot tarball
aur_plain_fetch_repo() { # $1=pkg $2=destdir -> prints checkout dir or fails
  local pkg="$1" dest="$2" outdir
  mkdir -p "$dest"; outdir="$dest/$pkg"; rm -rf "$outdir" 2>/dev/null || true; mkdir -p "$outdir"
  local tarball; tarball="$(mktemp -t aur-plain-XXXXXX.tar.gz)"
  if curl -fsSL "$(aur_plain_snapshot_url "$pkg")" -o "$tarball"; then
    if tar -xzf "$tarball" --strip-components=1 -C "$outdir" 2>/dev/null; then
      rm -f "$tarball"; is_valid_pkgb "$outdir/PKGBUILD" || { log_warn "Snapshot missing valid PKGBUILD"; return 1; }
      printf '%s\n' "$outdir"; return 0
    fi
  fi
  rm -f "$tarball" 2>/dev/null || true; return 1
}

# Plain PKGBUILD/.SRCINFO
aur_plain_fetch_plain_files() { # $1=pkg $2=destdir -> prints dir
  local pkg="$1" dir="$2/$1" cache_dir ttl now
  mkdir -p "$dir"
  cache_dir="${AUR_CACHE_DIR:-/tmp/aur-plain-cache}"; ttl="${AUR_CACHE_TTL_SEC:-3600}"; now="$(date +%s)"; mkdir -p "$cache_dir"
  if [ -f "$cache_dir/$pkg.PKGBUILD" ]; then
    local mtime; mtime="$(stat -c %Y "$cache_dir/$pkg.PKGBUILD" 2>/dev/null || echo 0)"
    if [ $((now - mtime)) -lt "$ttl" ]; then
      cp "$cache_dir/$pkg.PKGBUILD" "$dir/PKGBUILD" 2>/dev/null || true
      [ -s "$dir/PKGBUILD" ] && { printf '%s\n' "$dir"; return 0; }
    fi
  fi
  local CURL_OPTS; CURL_OPTS=(--fail --silent --show-error --location --compressed --connect-timeout 5 --max-time 20)
  if ! curl "${CURL_OPTS[@]}" "https://aur.archlinux.org/cgit/aur.git/plain/PKGBUILD?h=$pkg" -o "$dir/PKGBUILD"; then return 1; fi
  if ! is_valid_pkgb "$dir/PKGBUILD"; then
    log_warn "Downloaded PKGBUILD looked like HTML; retrying with ?plain=1"
    curl "${CURL_OPTS[@]}" "https://aur.archlinux.org/cgit/aur.git/tree/PKGBUILD?h=$pkg&plain=1" -o "$dir/PKGBUILD" || return 1
    is_valid_pkgb "$dir/PKGBUILD" || return 1
  fi
  cp "$dir/PKGBUILD" "$cache_dir/$pkg.PKGBUILD" 2>/dev/null || true
  if [ "${VERBOSE:-0}" = "1" ] || [ "${STRICT:-0}" = "1" ]; then
    curl "${CURL_OPTS[@]}" "https://aur.archlinux.org/cgit/aur.git/plain/.SRCINFO?h=$pkg" -o "$dir/.SRCINFO" || true
  fi
  printf '%s\n' "$dir"
}

aur_plain_fetch_any() { aur_plain_fetch_plain_files "$1" "$2" || aur_plain_fetch_repo "$1" "$2"; }

aur_plain_rpc_info() { # $1=pkg -> prints JSON (cached)
  local pkg="$1" cache_dir ttl now tmp
  cache_dir="${AUR_RPC_CACHE_DIR:-/tmp/aur-rpc-cache}"; ttl="${AUR_RPC_CACHE_TTL_SEC:-600}"; now="$(date +%s)"; mkdir -p "$cache_dir"
  if [ -f "$cache_dir/$pkg.json" ]; then
    local mtime; mtime="$(stat -c %Y "$cache_dir/$pkg.json" 2>/dev/null || echo 0)"
    if [ $((now - mtime)) -lt "$ttl" ] && [ -s "$cache_dir/$pkg.json" ]; then cat "$cache_dir/$pkg.json"; return 0; fi
  fi
  local CURL_OPTS; CURL_OPTS=(--fail --silent --show-error --location --compressed --connect-timeout 3 --max-time 6)
  tmp="$(mktemp -t aur-rpc-info-XXXXXX.json)"
  if curl "${CURL_OPTS[@]}" "https://aur.archlinux.org/rpc/v5/info/$pkg" -o "$tmp"; then
    if [ -s "$tmp" ]; then mv -f "$tmp" "$cache_dir/$pkg.json" 2>/dev/null || cp "$tmp" "$cache_dir/$pkg.json" 2>/dev/null || true; cat "$cache_dir/$pkg.json"; else rm -f "$tmp" 2>/dev/null || true; [ -s "$cache_dir/$pkg.json" ] && cat "$cache_dir/$pkg.json"; fi
  else rm -f "$tmp" 2>/dev/null || true; [ -s "$cache_dir/$pkg.json" ] && cat "$cache_dir/$pkg.json"; fi
}

aur_plain_rpc_info_live() { # $1=pkg -> prints JSON or nothing
  local pkg="$1"; local CURL_OPTS; CURL_OPTS=(--fail --silent --show-error --location --compressed --connect-timeout 3 --max-time 6)
  curl "${CURL_OPTS[@]}" "https://aur.archlinux.org/rpc/v5/info/$pkg" 2>/dev/null || true
}

aur_plain_exists() { # $1=pkg -> 0 if plain PKGBUILD is reachable
  local pkg="$1"; local CURL_OPTS; CURL_OPTS=(--fail --silent --show-error --location --compressed --connect-timeout 3 --max-time 6)
  curl "${CURL_OPTS[@]}" -H 'Range: bytes=0-64' "https://aur.archlinux.org/cgit/aur.git/plain/PKGBUILD?h=$pkg" >/dev/null 2>&1
}

aur_plain_rpc_search() { # $1=term -> print candidate package names (one per line)
  local term="$1" cache_dir ttl now; cache_dir="${AUR_RPC_CACHE_DIR:-/tmp/aur-rpc-cache}"; ttl="${AUR_RPC_CACHE_TTL_SEC:-600}"; now="$(date +%s)"; mkdir -p "$cache_dir"
  local f="$cache_dir/search_${term}.json"; if [ -f "$f" ]; then local mtime; mtime="$(stat -c %Y "$f" 2>/dev/null || echo 0)"; if [ $((now - mtime)) -lt "$ttl" ]; then :; else rm -f "$f" 2>/dev/null || true; fi; fi
  local CURL_OPTS; CURL_OPTS=(--fail --silent --show-error --location --compressed --connect-timeout 3 --max-time 6)
  [ -f "$f" ] || curl "${CURL_OPTS[@]}" "https://aur.archlinux.org/rpc/v5/search/$term" -o "$f" 2>/dev/null || true
  [ -s "$f" ] || return 1
  grep -o '"Name":"[^"]\+"' "$f" | sed 's/.*:"//;s/"$//' | sort -u
}
