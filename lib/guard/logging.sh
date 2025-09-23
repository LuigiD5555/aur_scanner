# SPDX-License-Identifier: MIT
# Copyright (c) 2025 José Luis López López Prieto
# Author GitHub: https://github.com/LuigiD5555
# lib/guard/logging.sh — canonical logging helpers (shared by scan & aur-verify)

# Behavior via env:
#   QUIET=1     -> suprime INFO y WARN
#   DEBUG=1     -> habilita log_debug
#   LOG_TAG=... -> prefijo del módulo, ej. "scan" o "aur-verify"

# Avoid redefining if already sourced
if declare -F log_info >/dev/null 2>&1; then
  return 0
fi

_log_print() {
  # $1 = LEVEL, $2.. = message
  local level="$1"; shift
  local tag="${LOG_TAG:-app}"
  printf '[%s]%s %s\n' "$level" "${tag:+[$tag]}" "$*" >&2
}

log_info()  { [ "${QUIET:-0}" = "1" ] && return; _log_print "INFO"  "$@"; }
log_warn()  { [ "${QUIET:-0}" = "1" ] && return; _log_print "WARN"  "$@"; }
log_error() { _log_print "ERROR" "$@"; }
log_debug() { [ "${DEBUG:-0}" = "1" ] || return 0; _log_print "DEBUG" "$@"; }

die() {
  log_error "$@"
  exit 1
}
