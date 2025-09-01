#!/usr/bin/env bash
# common.sh — shell safety and small utilities

# Ensure bash is used (arrays, regex, mapfile used elsewhere)
if [ -z "${BASH_VERSION:-}" ]; then
  exec bash "$0" "$@"
fi

set -euo pipefail
IFS=$'\n\t'

have_cmd() { command -v "$1" >/dev/null 2>&1; }
require_tools() { for c in "$@"; do have_cmd "$c" || { echo "[ERROR] Missing required command: $c" >&2; exit 1; }; done; }

