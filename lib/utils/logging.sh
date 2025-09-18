#!/usr/bin/env bash
# SPDX-License-Identifier: MIT
# Copyright (c) 2025 José Luis López López Prieto
# Author GitHub: https://github.com/LuigiD5555
# logging.sh — uniform logging helpers

log_info()  { [ "${QUIET:-0}" = "1" ] && return; printf '[INFO] %s\n' "$*" >&2; }
log_warn()  { [ "${QUIET:-0}" = "1" ] && return; printf '[WARN] %s\n' "$*" >&2; }
log_error() { printf '[ERROR] %s\n' "$*" >&2; }
die()       { log_error "$*"; exit 1; }
