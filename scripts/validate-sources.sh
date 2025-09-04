#!/usr/bin/env bash
# License: CC BY-NC-SA 4.0 (https://creativecommons.org/licenses/by-nc-sa/4.0/)
# Copyright (c) 2025 José Luis López López Prieto
# validate-sources.sh — checks that sourced files exist after refactors
set -euo pipefail
shopt -s nullglob

fail=0
root_dir=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)

extract_path() {
  # $1=line -> prints path without quotes
  local line="$1" p
  # Try double-quoted form first
  p=$(printf '%s' "$line" | awk 'match($0,/source[[:space:]]+"[^"]+"/,m){s=m[0]; sub(/^.*source[[:space:]]+"/,"",s); sub(/".*$/,"",s); print s; exit}')
  if [ -z "${p:-}" ]; then
    # Single-quoted form
    p=$(printf '%s' "$line" | awk "match(\$0,/source[[:space:]]+'[^']+'/,m){s=m[0]; sub(/^.*source[[:space:]]+'/,\"\",s); sub(/'.*\$/,\"\",s); print s; exit}")
  fi
  [ -n "${p:-}" ] && printf '%s\n' "$p"
}

while IFS= read -r -d '' f; do
  filedir=$(cd -- "$(dirname -- "$f")" && pwd)
  while IFS= read -r line; do
    p=$(extract_path "$line") || true
    [ -n "${p:-}" ] || continue
    # replace common vars
    p=${p//\$SCRIPT_DIR/$filedir}
    p=${p//\$LIB_DIR/$root_dir/lib}
    # normalize path using python if available
    if command -v python >/dev/null 2>&1; then
      path=$(python - <<PY 2>/dev/null || echo "$p"
import os
print(os.path.normpath("$p"))
PY
)
    else
      path="$p"
    fi
    if [ ! -f "$path" ]; then
      printf '[validate-sources] Missing: %s (referenced in %s)\n' "$path" "$f" >&2
      fail=1
    fi
  done < <(grep -E "^[[:space:]]*source[[:space:]]+['\"]" "$f" || true)
done < <(find "$root_dir/bin" "$root_dir/lib" -type f -name '*.sh' -print0)

exit $fail
