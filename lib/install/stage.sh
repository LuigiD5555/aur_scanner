# SPDX-License-Identifier: MIT
# Copyright (c) 2025 José Luis López López Prieto <ing.jlllopezp@gmail.com>
# Author GitHub: https://github.com/LuigiD5555
# shellcheck shell=bash
# Staging runtime: copy bin/* and lib/** into PREFIX_LIB with proper permissions.

has_shebang() {
  head -c 2 -- "$1" 2>/dev/null | grep -q "^#!"
}

stage_runtime() {
  # $1 = REPO_ROOT, $2 = PREFIX_LIB
  local root="$1" prefix_lib="$2"
  local src_bin="$root/bin"
  local src_lib="$root/lib"
  local dst_bin="$prefix_lib/bin"
  local dst_lib="$prefix_lib/lib"

  mkdir -p "$dst_bin" "$dst_lib"

  # Copy bin files (flat)
  if [[ -d "$src_bin" ]]; then
    find "$src_bin" -maxdepth 1 -type f -print0 | while IFS= read -r -d '' f; do
      local base; base="$(basename "$f")"
      install -m 0644 "$f" "$dst_bin/$base"
      if has_shebang "$f"; then chmod 0755 "$dst_bin/$base"; fi
    done
  fi

  # Copy lib tree (structure preserved)
  if [[ -d "$src_lib" ]]; then
    ( cd "$src_lib" && find . -type f ! -path '*/.git/*' ! -name '*.zip' -print0 ) |
      while IFS= read -r -d '' rel; do
        local src="$src_lib/$rel"
        local dst="$dst_lib/$rel"
        mkdir -p "$(dirname "$dst")"
        install -m 0644 "$src" "$dst"
        if has_shebang "$src"; then chmod 0755 "$dst"; fi
      done
  fi

  log "Runtime staged into: $prefix_lib"
}
