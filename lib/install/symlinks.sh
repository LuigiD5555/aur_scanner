# SPDX-License-Identifier: MIT
# Copyright (c) 2025 José Luis López López Prieto <ing.jlllopezp@gmail.com>
# Author GitHub: https://github.com/LuigiD5555
# shellcheck shell=bash
# Create launcher and helper symlinks

link_one() {
  local src="$1" dst="$2"
  ln -sf "$src" "$dst"
  log "Linked $dst -> $src"
}

link_launcher_and_helpers() {
  # $1 = GUARD_RESOLVED, $2 = SHIM_RESOLVED, $3 = DEST_BIN, $4.. = helpers
  local guard="$1" shim="$2" dest_bin="$3"; shift 3
  local helpers=("$@")

  link_one "$guard" "$dest_bin/scan"

  local h
  for h in "${helpers[@]}"; do
    link_one "$shim" "$dest_bin/$h"
  done
}
