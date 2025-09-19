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
  # $1 = GUARD_RESOLVED, $2 = DEST_BIN, $3.. = helpers
  local guard="$1" dest_bin="$2"; shift 2
  local helpers=("$@")

  link_one "$guard" "$dest_bin/aur-guard"

  local h
  for h in "${helpers[@]}"; do
    link_one "$guard" "$dest_bin/$h"
  done
}
