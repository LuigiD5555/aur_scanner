#!/usr/bin/env bash
# log.sh — logging helpers

log_info()  { [ "${QUIET:-0}" = "1" ] && return; printf '[INFO] %s\n' "$*" >&2; }
log_warn()  { [ "${QUIET:-0}" = "1" ] && return; printf '[WARN] %s\n' "$*" >&2; }
log_error() { printf '[ERROR] %s\n' "$*" >&2; }
die()       { log_error "$*"; exit 1; }
