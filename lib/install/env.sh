# SPDX-License-Identifier: MIT
# Copyright (c) 2025 José Luis López López Prieto <ing.jlllopezp@gmail.com>
# Author GitHub: https://github.com/LuigiD5555
# shellcheck shell=bash
# Env defaults and constants for installer

# Wrapper basename in repo (adjust if your file is 'scan.sh')
: "${GUARD_BASENAME:=scan}"

# Helpers we want to optionally intercept
HELPERS=(yay paru pikaur trizen pamac)

# Minimal Node.js version
: "${MIN_NODE:=16.0.0}"
