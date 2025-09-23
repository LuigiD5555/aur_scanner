#!/usr/bin/env bash
# Generic command stub used in tests. It delegates to handler scripts declared
# via environment variables (STUB_<COMMAND>=/path/to/script).

set -euo pipefail

cmd="$(basename -- "$0")"
upper=$(printf '%s' "$cmd" | tr '[:lower:]-' '[:upper:]_')
var="STUB_${upper}"
handler="${!var:-${STUB_DEFAULT:-}}"

if [[ -n "${handler:-}" ]]; then
  export STUB_COMMAND="$cmd"
  exec bash "$handler" "$@"
fi

echo "[tests][stub] No handler set for $cmd" >&2
exit 97
