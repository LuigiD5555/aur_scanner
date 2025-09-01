#!/usr/bin/env bash
# pkgb.sh — helpers to analyze PKGBUILD

ALLOWED_DOMAINS="${ALLOWED_DOMAINS:-github.com|codeload.github.com|objects.githubusercontent.com|gitlab.com}"

has_strong_sums() { grep -Eq '^[[:space:]]*(sha256sums|sha512sums)='; }
has_weak_or_skip() { grep -Eq '^[[:space:]]*(md5sums|sha1sums)=' || grep -Eq '(^|[[:space:]])SKIP([[:space:]]|\")'; }

list_sources() {
  sed -n "s/^[[:space:]]*source[[:space:]]*=[[:space:]]*(\(.*\))/\1/p" \
    | tr ' ' '\n' | tr -d '"' "'" \
    | sed "s/[()']//g" | grep -E '^(https?|git|ftp)://|::https?://|::git://'
}

sources_have_only_https() { awk '!/^https:\/\// {bad=1} END{exit bad}'; }
sources_domains_allowed() { grep -Ev "$ALLOWED_DOMAINS" >/dev/null && return 1 || return 0; }

print_func_summaries() {
  awk '
    /^prepare\(\)/ {inp=1; print "---- prepare() ----"; next}
    /^build\(\)/   {inb=1; print "---- build() ----";   next}
    /^package\(\)/ {inpkg=1; print "---- package() ----";next}
    inp && /^\}/ {inp=0} inb && /^\}/ {inb=0} inpkg && /^\}/ {inpkg=0}
    inp||inb||inpkg { print }
  ' "$1" | sed 's/^[[:space:]]\{0,2\}//'
}

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

scan_red_flags() { # PKGBUILD path
  grep -Eni \
    -e 'curl[[:space:]]*\|[[:space:]]*sh' \
    -e 'wget[[:space:]]*\|[[:space:]]*sh' \
    -e 'eval[[:space:]]' \
    -e 'base64[[:space:]]*-d' \
    -e 'openssl[[:space:]]+enc' \
    -e '/dev/tcp' \
    -e 'rm[[:space:]]*-rf[[:space:]]+/' \
    -e 'useradd[[:space:]]' \
    -e 'systemctl[[:space:]]' \
    -e 'setcap[[:space:]]' \
    -e 'chmod[[:space:]]4[0-9]{3}' \
    -e 'python[[:space:]]+-c' \
    -e 'perl[[:space:]]+-e' \
    -e 'ruby[[:space:]]+-e' \
    -e 'node[[:space:]]+-e' \
    "$1" || true
}

