#!/usr/bin/env bash
# pkgb.sh — helpers to analyze PKGBUILD

ALLOWED_DOMAINS="${ALLOWED_DOMAINS:-github.com|codeload.github.com|objects.githubusercontent.com|gitlab.com}"

has_strong_sums() { grep -Eq '^[[:space:]]*(sha256sums|sha512sums)='; }
has_weak_or_skip() { grep -Eq '^[[:space:]]*(md5sums|sha1sums)=' || grep -Eq '(^|[[:space:]])SKIP([[:space:]]|\")'; }

list_sources() {
  sed -n "s/^[[:space:]]*source[[:space:]]*=[[:space:]]*(\(.*\))/\1/p" \
    | tr ' ' '\n' | tr -d "\"'" \
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
  local pkgb="$1" script_dir rules
  script_dir=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)
  rules="$script_dir/rules/redflags.list"
  if [ -f "$rules" ]; then
    # Use extended regexes from shared list; ignore comments/blank lines
    # Build a temporary pattern file without comments for grep -f
    local tmp; tmp="$(mktemp -t redflags-XXXXXX.regex)"
    awk 'BEGIN{IGNORECASE=0} /^[[:space:]]*#/ {next} NF>0 {print}' "$rules" > "$tmp"
    grep -Eni -E -f "$tmp" "$pkgb" || true
    rm -f "$tmp" >/dev/null 2>&1 || true
  else
    # Fallback (should rarely be used): inline patterns
    grep -Eni \
      -e 'curl[[:space:]]*\|[[:space:]]*(sh|bash)' \
      -e 'wget[[:space:]]*\|[[:space:]]*(sh|bash)' \
      -e '\beval\b[[:space:]]' \
      -e 'base64[[:space:]]*-d.*\|' \
      -e 'openssl[[:space:]]+enc' \
      -e '/dev/tcp' \
      -e 'rm[[:space:]]*-rf[[:space:]]+(/|\$)' \
      -e '\buseradd\b[[:space:]]' \
      -e '\bsystemctl\b[[:space:]]+(enable|start)' \
      -e '\bsetcap\b[[:space:]]' \
      -e 'chmod[[:space:]][47][0-9]{3}' \
      -e '\bpython\b[[:space:]]+-c' \
      -e '\bperl\b[[:space:]]+-e' \
      -e '\bruby\b[[:space:]]+-e' \
      -e '\bnode\b[[:space:]]+-e' \
      -e '\$\(.*curl.*\)' \
      -e 'dd[[:space:]]+if=.*of=/' \
      -e '\bmount\b[[:space:]]+' \
      -e '\bumount\b[[:space:]]+' \
      -e '\bsu\b[[:space:]]+-c' \
      -e '\bsudo\b[[:space:]]+' \
      -e '\bpkexec\b[[:space:]]+' \
      "$pkgb" || true
  fi
}

# pkgb_check_vcs_pinning — warn on git+ sources without #commit= or #tag=
pkgb_check_vcs_pinning() { # $1=PKGBUILD
  local pkgb="$1" unpinned=0
  local sources
  sources="$(sed -n 's/^[[:space:]]*source[[:space:]]*=[[:space:]]*(\(.*\))/\1/p' "$pkgb" \
            | tr ' ' '\n' | tr -d "\"'" | sed 's/[()]//g')"
  while IFS= read -r s; do
    [ -z "$s" ] && continue
    case "$s" in *::*) s="${s#*::}";; esac
    case "$s" in
      git+http*|git+https*)
        if ! printf '%s' "$s" | grep -Eq '#(commit|tag)='; then
          log_warn "Unpinned VCS source: $s (add #commit= or #tag= per VCS guidelines)"
          unpinned=1
        fi
        ;;
    esac
  done <<EOF
$sources
EOF
  return $unpinned
}
