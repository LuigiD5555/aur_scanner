#!/usr/bin/env bash
# License: CC BY-NC-SA 4.0 (https://creativecommons.org/licenses/by-nc-sa/4.0/)
# Copyright (c) 2025 José Luis López López Prieto
# derive_candidates_from_repo.sh — GitHub URL parsing and README/title based candidates

is_github_url() { [[ "$1" =~ ^https?://github\.com/[^/]+/[^/]+(\.git)?/?$ ]]; }

github_owner_repo() { # prints "owner repo"
  local url="$1" path owner repo
  path="${url#https://github.com/}"; path="${path#http://github.com/}"
  path="${path%%\?*}"; path="${path%%#*}"; path="${path%/}"; path="${path%.git}"
  owner="${path%%/*}"; repo="${path##*/}"
  printf '%s %s\n' "$owner" "$repo"
}

safe_repo_from_url() { # extra-safe repo extraction
  local url="$1" repo
  repo="$(printf '%s' "$url" | sed -E 's|.*/github.com/[^/]+/([^/?#]+).*|\1|' | sed -E 's/\.git$//' | sed -E 's|/+$||')"
  [ -n "$repo" ] && printf '%s\n' "$repo" || printf 'unknown\n'
}

github_default_branch() { # $1=owner $2=repo -> prints branch or empty
  git ls-remote --symref "https://github.com/$1/$2" HEAD 2>/dev/null \
    | awk '/^ref:/ {print $2}' | sed -n 's@^refs/heads/@@p' | head -n1
}

try_fetch_readme() { # $1=owner $2=repo $3=branch -> prints README or empty
  local owner="$1" repo="$2" br="$3" url content
  for name in README.md README.rst README.txt README; do
    url="https://raw.githubusercontent.com/${owner}/${repo}/${br}/${name}"
    if content="$(curl -fsSL "$url" 2>/dev/null)"; then
      printf '%s\n' "$content"; return 0
    fi
  done
  return 1
}

extract_title_from_readme() { # stdin -> title-ish line
  local data title
  data="$(cat)"
  title="$(printf '%s\n' "$data" | sed -n 's/^#[[:space:]]\{0,1\}//p' | head -n1)"
  if [ -n "$title" ]; then printf '%s\n' "$title"; else
    printf '%s\n' "$data" | sed -n '/[^[:space:]]/ {s/^[[:space:]]*//;p; q;}'
  fi
}

normalize_kebab() { printf '%s' "$1" | tr '[:upper:]' '[:lower:]' | sed 's/[^a-z0-9[:space:]-]/ /g' | tr ' ' '-' | tr -s '-'; }

build_candidates_from_github() { # $1=url
  local url="$1" owner repo branch title kebab
  read -r owner repo <<<"$(github_owner_repo "$url")" || { owner=""; repo=""; }
  if [ -z "$repo" ]; then repo="$(safe_repo_from_url "$url")"; fi
  branch="$(github_default_branch "$owner" "$repo")"; [ -z "$branch" ] && branch="main"
  log_info "GitHub repo: $owner/$repo (branch: $branch)"
  local readme=""
  if readme="$(try_fetch_readme "$owner" "$repo" "$branch" 2>/dev/null)"; then
    title="$(printf '%s' "$readme" | extract_title_from_readme | head -n1 | tr -d '\r')"
    [ -n "$title" ] && log_info "README title: $title"; kebab="$(normalize_kebab "$title")"
  else
    log_warn "Unable to fetch README; falling back to repo name only."
  fi
  local -a base out; base=()
  [ -n "${kebab:-}" ] && base+=("$kebab")
  local repo_kebab; repo_kebab="$(normalize_kebab "$repo")"; [ -n "$repo_kebab" ] && base+=("$repo_kebab")
  mapfile -t base < <(printf '%s\n' "${base[@]}" | grep -E '.+' | awk '!seen[$0]++')
  out=()
  for b in "${base[@]}"; do out+=("$b" "${b}-git" "${b}-bin" "${b}-appimage"); done
  [ "${#out[@]}" -eq 0 ] && out=("$repo_kebab")
  printf '%s\n' "${out[@]}" | awk '!seen[$0]++'
}
