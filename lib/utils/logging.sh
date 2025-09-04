#!/usr/bin/env bash
# License: CC BY-NC-SA 4.0 (https://creativecommons.org/licenses/by-nc-sa/4.0/)
# Copyright (c) 2025 José Luis López López Prieto
# logging.sh — uniform logging helpers

log_info()  { [ "${QUIET:-0}" = "1" ] && return; printf '[INFO] %s\n' "$*" >&2; }
log_warn()  { [ "${QUIET:-0}" = "1" ] && return; printf '[WARN] %s\n' "$*" >&2; }
log_error() { printf '[ERROR] %s\n' "$*" >&2; }
die()       { log_error "$*"; exit 1; }
