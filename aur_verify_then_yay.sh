#!/usr/bin/env bash
# Wrapper for backward compatibility: delegate to modular entrypoint

# Ensure we run under bash even if invoked via `sh ./aur_verify_then_yay.sh`
if [ -z "${BASH_VERSION:-}" ]; then
  exec bash "$0" "$@"
fi

SCRIPT_DIR=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)
# Call the new entrypoint; use bash to avoid needing +x on the target
exec bash "$SCRIPT_DIR/bin/aur-verify" "$@"

