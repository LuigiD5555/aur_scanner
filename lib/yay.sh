#!/usr/bin/env bash
# yay.sh — helpers around yay query output

# Requires: YAY_BIN to be set by caller

yay_query_any() { "$YAY_BIN" -Si "$1" 2>/dev/null; }

yay_field() { # $1=pkg  $2=Field Name
  local out
  out="$(yay_query_any "$1")" || return 1
  printf '%s\n' "$out" | sed -n "s/^$2[[:space:]]*:[[:space:]]*//p" | head -n1
}

yay_repo_of()    { yay_field "$1" "Repository" | tr '[:upper:]' '[:lower:]'; }
yay_exists_any() { yay_query_any "$1" >/dev/null; }
yay_exists_aur() { [ "$(yay_repo_of "$1")" = "aur" ]; }

