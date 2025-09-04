#!/usr/bin/env bash
# search.sh — searching AUR via yay, strict name filters, resolution

prefer_fast_variant() { # stdin -> reordered list
  awk '{
    a[NR]=$0
  } END {
    for(i=1;i<=NR;i++) if (a[i] ~ /-bin$/ || a[i] ~ /-appimage$/) print a[i]
    for(i=1;i<=NR;i++) if (!(a[i] ~ /-bin$/ || a[i] ~ /-appimage$/)) print a[i]
  }'
}

# Alternative simpler AUR search that doesn't rely on helper functions
aur_search_simple() { # $1=search_term $2=regex -> print only AUR pkgs
  local term="$1" pattern="$2"
  log_info "Simple AUR search for: '$term' with pattern: '$pattern'"
  
  "$YAY_BIN" -Ss "$term" 2>/dev/null | awk -v pat="$pattern" '
    /^aur\// { 
      # Extract package name 
      line = $0
      sub(/^aur\//, "", line)
      split(line, parts, " ")
      pkg_name = parts[1]
      if (pkg_name != "" && pkg_name ~ pat) {
        print pkg_name
      }
    }
  ' | sort -u
}

# Name-strict AUR search (compat): use yay -Ss (names), filter by regex and repo==aur
aur_search_name_strict_aur_only() { # $1=search_term $2=regex -> print only AUR pkgs
  local term="$1" pattern="$2"
  # Prefer AUR RPC search in QUIET (faster), fallback to yay-based search otherwise
  if [ "${QUIET:-0}" = "1" ]; then
    aur_plain_rpc_search "$term" 2>/dev/null | grep -E "$pattern" | sort -u
    return 0
  fi
  log_info "Searching AUR for term: '$term' with pattern: '$pattern'"
  local search_output
  search_output="$("$YAY_BIN" -Ss "$term" 2>/dev/null)" || {
    log_warn "yay -Ss '$term' failed or returned no results"
    return 1
  }
  [ -n "$search_output" ] || { log_warn "yay -Ss '$term' returned empty output"; return 1; }
  log_info "Raw search output for debugging:"
  printf '%s\n' "$search_output" | head -5 | sed 's/^/  DEBUG: /' >&2
  local simple_results
  simple_results="$(aur_search_simple "$term" "$pattern")"
  if [ -n "$simple_results" ]; then
    log_info "Simple search found results, using those"
    printf '%s\n' "$simple_results"
    return 0
  fi
  printf '%s\n' "$search_output" | awk '
    /^aur\// { 
      line = $0
      sub(/^aur\//, "", line)
      split(line, parts, " ")
      pkg_name = parts[1]
      if (pkg_name != "") print pkg_name
    }
  ' | grep -E "$pattern" | sort -u | while read -r name; do
    log_info "Checking candidate: '$name'"
    if yay_exists_any "$name" && [ "$(yay_repo_of "$name")" = "aur" ]; then
      printf '%s\n' "$name"
    else
      log_warn "Candidate '$name' failed verification"
    fi
  done
}

select_from_list() { # stdin list -> chosen (menu on stderr, choice on stdout)
  local -a items; mapfile -t items
  [ "${#items[@]}" -gt 0 ] || return 1
  if [ "$NO_PROMPT" = "1" ]; then
    log_warn "Multiple candidates (NO_PROMPT=1):"
    printf '  - %s\n' "${items[@]}" >&2
    return 2
  fi
  echo "Select a package:" >&2
  local i; for i in "${!items[@]}"; do printf ' [%d] %s\n' "$((i+1))" "${items[$i]}" >&2; done
  printf 'Enter number: ' >&2
  local sel; read -r sel
  case "$sel" in (''|*[!0-9]*) return 1;; esac
  [ "$sel" -ge 1 ] && [ "$sel" -le "${#items[@]}" ] || return 1
  printf '%s\n' "${items[$((sel-1))]}"
}

resolve_pkg() { # $1=input -> print AUR pkg (stdout only)
  local input="$1" candidates=() c regex
  if is_github_url "$input"; then
    log_info "Input looks like a GitHub URL. Deriving candidates from README/title…"
    mapfile -t candidates < <(build_candidates_from_github "$input")
    # Hard fallback: if no candidates were produced, fallback to repo basename
    if [ "${#candidates[@]}" -eq 0 ]; then
      local fallback_repo
      fallback_repo="$(safe_repo_from_url "$input")"
      candidates=("$fallback_repo" "${fallback_repo}-git" "${fallback_repo}-bin" "${fallback_repo}-appimage")
    fi
  else
    # If the user explicitly provided a suffixed name (-git|-bin|-appimage),
    # respect it and return it directly rather than "des-suffixing" later.
    # This avoids resolving to the base package when the user asked for a variant.
    local lower; lower="$(printf '%s' "$input" | tr '[:upper:]' '[:lower:]')"
    if printf '%s' "$lower" | grep -Eq '(-git|-bin|-appimage)$'; then
      printf '%s\n' "$(normalize_kebab "$lower")"
      return 0
    fi
    local b; b="$(normalize_kebab "$input")"
    candidates=("$b" "${b}-git" "${b}-bin" "${b}-appimage")
  fi

  [ "$FAST" = "1" ] && mapfile -t candidates < <(printf '%s\n' "${candidates[@]}" | prefer_fast_variant)

  # Exact AUR match check via RPC (faster than yay)
  # Prefer the base candidate strongly: try cache + live + second live before variants
  local base rest
  base="${candidates[0]}"
  try_exact() {
    local name="$1" info
    info="$(aur_plain_rpc_info "$name" 2>/dev/null || true)"
    if printf '%s' "$info" | grep -Eq '"resultcount"[[:space:]]*:[[:space:]]*1' \
       && printf '%s' "$info" | grep -Eq '"Name"[[:space:]]*:[[:space:]]*"'$name'"'; then
      printf '%s\n' "$name"; return 0
    fi
    info="$(aur_plain_rpc_info_live "$name" 2>/dev/null || true)"
    if [ -n "$info" ] \
       && printf '%s' "$info" | grep -Eq '"resultcount"[[:space:]]*:[[:space:]]*1' \
       && printf '%s' "$info" | grep -Eq '"Name"[[:space:]]*:[[:space:]]*"'$name'"'; then
      printf '%s\n' "$name"; return 0
    fi
    return 1
  }
  # Try base with extra care (two live attempts if needed)
  if try_exact "$base"; then return 0; fi
  # Second live try for base to reduce transient DNS glitches
  local info2
  info2="$(aur_plain_rpc_info_live "$base" 2>/dev/null || true)"
  if [ -n "$info2" ] \
     && printf '%s' "$info2" | grep -Eq '"resultcount"[[:space:]]*:[[:space:]]*1' \
     && printf '%s' "$info2" | grep -Eq '"Name"[[:space:]]*:[[:space:]]*"'$base'"'; then
    printf '%s\n' "$base"; return 0
  fi
  # If RPC was flakey, do a lightweight existence probe via plain endpoint
  if aur_plain_exists "$base"; then
    printf '%s\n' "$base"; return 0
  fi
  # Then try the remaining candidates
  rest=("${candidates[@]:1}")
  for c in "${rest[@]}"; do
    if try_exact "$c"; then return 0; fi
  done

  # Build strict regex from best candidate:
  # Prefer a dashed base WITHOUT suffix (-git|-bin|-appimage), taking the first
  # in candidates order (so README-derived names win).
  local dashed head
  dashed="$(
    printf '%s\n' "${candidates[@]}" \
      | grep -E '^[a-z0-9]+(-[a-z0-9]+)+$' \
      | grep -Ev '(-git|-bin|-appimage)$' \
      | head -n1
  )"

  if [ -n "$dashed" ]; then
    regex="^${dashed}(-git|-bin|-appimage)?$"
  else
    head="$(printf '%s' "${candidates[0]}")"; head="${head%%-*}"
    regex="^${head}([^-].*)?$"
  fi

  # search_term to feed into yay -Ss (no anchors), while regex stays anchored
  local search_term
  if [ -n "$dashed" ]; then
    search_term="$dashed"
  else
    search_term="$head"
  fi

  log_info "No exact AUR match. Expanding with name-strict AUR search: /$regex/"
  local -a hits=()
  # Try AUR RPC search first (fast)
  mapfile -t hits < <(aur_plain_rpc_search "$search_term" 2>/dev/null | grep -E "$regex" | sort -u)
  # Fallback to yay-based search only if needed
  if [ "${#hits[@]}" -eq 0 ]; then
    mapfile -t hits < <(aur_search_name_strict_aur_only "$search_term" "$regex")
  fi

  if [ "${#hits[@]}" -eq 0 ]; then
    head="$(printf '%s' "${candidates[0]}")"; head="${head%%-*}"
    log_info "No matches with dashed term, trying with base: '$head'"
    mapfile -t hits < <(aur_search_name_strict_aur_only "$head" "^${head}([-].*)?$")
  fi

  [ "${#hits[@]}" -gt 0 ] || { log_warn "No AUR candidates matched by name."; return 1; }
  [ "${#hits[@]}" -eq 1 ] && { printf '%s\n' "${hits[0]}"; return 0; }

  log_info "Multiple AUR candidates after strict filtering."
  local chosen
  if chosen="$(printf '%s\n' "${hits[@]}" | select_from_list)"; then
    printf '%s\n' "$chosen"; return 0
  else
    return 1
  fi
}
