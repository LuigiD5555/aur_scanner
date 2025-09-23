#!/usr/bin/env bash
# sudo stub: simply executes the command without elevation.
set -euo pipefail

while [[ $# -gt 0 ]]; do
  case "$1" in
    -n|-E|-A|-b)
      shift
      ;;
    --)
      shift
      break
      ;;
    -*)
      shift
      ;;
    *)
      break
      ;;
  esac
done

exec "$@"
