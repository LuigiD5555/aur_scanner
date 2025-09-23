# SPDX-License-Identifier: MIT
# Copyright (c) 2025 José Luis López López Prieto
# Author GitHub: https://github.com/LuigiD5555
# lib/guard/runtime.sh
# Runtime helpers (resolve real helper binary)

guard_find_real_cmd() {
  local tool="$1" upper override_var override_path path cand
  upper="$(printf '%s' "$tool" | tr '[:lower:]' '[:upper:]')"
  override_var="SCAN_REAL_${upper}"
  override_path="${!override_var:-}"

  if [[ -n "$override_path" && -x "$override_path" ]]; then
    printf '%s\n' "$override_path"
    return 0
  fi

  if path="$(command -v -- "$tool" 2>/dev/null)"; then
    local real self
    real="$(readlink -f "$path" 2>/dev/null || printf '%s' "$path")"
    self="$(readlink -f "$_self_path" 2>/dev/null || printf '%s' "$_self_path")"
    if [[ "$real" != "$self" ]]; then
      printf '%s\n' "$path"
      return 0
    fi
  fi

  for cand in "/usr/bin/$tool" "/bin/$tool" "/usr/local/bin/$tool"; do
    if [[ -x "$cand" ]]; then
      local real self
      real="$(readlink -f "$cand" 2>/dev/null || printf '%s' "$cand")"
      self="$(readlink -f "$_self_path" 2>/dev/null || printf '%s' "$_self_path")"
      if [[ "$real" != "$self" ]]; then
        printf '%s\n' "$cand"
        return 0
      fi
    fi
  done

  return 1
}
