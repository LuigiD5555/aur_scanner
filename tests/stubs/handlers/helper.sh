#!/usr/bin/env bash
# Generic stub for pacman-like helpers (yay, paru, pikaur, trizen, pacman) and pamac.
# Controlled via env vars:
#   HELPER_STUB_SEARCH_OUTPUT : printed when -Ss is used
#   HELPER_STUB_QUM_OUTPUT    : printed when -Qum is used
#   HELPER_STUB_INSTALL_EXIT  : exit status for install (-S / build)
#   HELPER_STUB_ARGS_LOG      : path to file where arguments are logged (optional)

set -euo pipefail

cmd="${STUB_COMMAND:-helper}"
args=("$@")

if [[ -n "${HELPER_STUB_ARGS_LOG:-}" ]]; then
  printf '%s %s\n' "$cmd" "${args[*]}" >>"$HELPER_STUB_ARGS_LOG"
fi

is_pamac=0
[[ "$cmd" == "pamac" ]] && is_pamac=1

joined=" ${args[*]} "

if [[ "$joined" == *" -Ss "* || "$joined" == *" --search "* ]]; then
  printf '%s\n' "${HELPER_STUB_SEARCH_OUTPUT:-aur/example 1.0-1}" \
    || true
  exit 0
fi

if [[ "$joined" == *" -Qum"* ]]; then
  printf '%s\n' "${HELPER_STUB_QUM_OUTPUT:-aur/pkg1 1.0-1 -> 1.0-2}" \
    || true
  exit 0
fi

if [[ $is_pamac -eq 1 ]]; then
  exit "${HELPER_STUB_INSTALL_EXIT:-0}"
fi

if [[ "$joined" == *" -S "* || "$joined" == *" -U "* ]]; then
  exit "${HELPER_STUB_INSTALL_EXIT:-0}"
fi

exit 0
