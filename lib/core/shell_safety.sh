#!/usr/bin/env bash
# License: CC BY-NC-SA 4.0 (https://creativecommons.org/licenses/by-nc-sa/4.0/)
# Copyright (c) 2025 José Luis López López Prieto
# shell_safety.sh — strict bash settings and small utilities

# Ensure bash is used (arrays, regex, mapfile)
if [ -z "${BASH_VERSION:-}" ]; then
  exec bash "$0" "$@"
fi

set -euo pipefail
IFS=$'\n\t'

have_cmd() { command -v "$1" >/dev/null 2>&1; }
require_tools() { for c in "$@"; do have_cmd "$c" || { echo "[ERROR] Missing required command: $c" >&2; exit 1; }; done; }
