#!/usr/bin/env bash
set -euo pipefail
if [[ $# -eq 0 || "$1" == "-v" || "$1" == "--version" ]]; then
  printf 'v%s\n' "${NODE_STUB_VERSION:-18.0.0}"
  exit 0
fi
if [[ "$1" == "--test-fail" ]]; then
  exit 1
fi
exit 0
