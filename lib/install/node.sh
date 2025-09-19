# SPDX-License-Identifier: MIT
# Copyright (c) 2025 José Luis López López Prieto <ing.jlllopezp@gmail.com>
# Author GitHub: https://github.com/LuigiD5555
# shellcheck shell=bash
# Ensure Node.js >= MIN_NODE and helper functions to install it.

ver_ge() { # return 0 if $1 >= $2 (major.minor.patch)
  local IFS=.
  local -a A=($1) B=($2)
  while ((${#A[@]}<3)); do A+=("0"); done
  while ((${#B[@]}<3)); do B+=("0"); done
  local i a b
  for i in 0 1 2; do
    a=${A[$i]:-0}; b=${B[$i]:-0}
    if ((10#$a > 10#$b)); then return 0; fi
    if ((10#$a < 10#$b)); then return 1; fi
  done
  return 0
}

get_node_version() {
  command -v node >/dev/null 2>&1 || { echo ""; return 0; }
  local v; v="$(node -v 2>/dev/null || true)"
  printf '%s\n' "${v#v}"
}

try_install_pkgs() { # $@ pkgs...
  local pkgs=("$@")
  if command -v pacman >/dev/null 2>&1; then
    log "Installing with pacman: ${pkgs[*]}"
    sudo pacman -Sy --needed --noconfirm "${pkgs[@]}"
    return 0
  fi
  if command -v pamac >/dev/null 2>&1; then
    log "Installing with pamac: ${pkgs[*]}"
    pamac install --no-confirm "${pkgs[@]}"
    return 0
  fi
  if command -v yay >/dev/null 2>&1; then
    log "Installing with yay: ${pkgs[*]}"
    yay -S --needed --noconfirm "${pkgs[@]}"
    return 0
  fi
  if command -v paru >/dev/null 2>&1; then
    log "Installing with paru: ${pkgs[*]}"
    paru -S --needed --noconfirm "${pkgs[@]}"
    return 0
  fi
  if command -v pikaur >/dev/null 2>&1; then
    log "Installing with pikaur: ${pkgs[*]}"
    pikaur -S --needed --noconfirm "${pkgs[@]}"
    return 0
  fi
  if command -v trizen >/dev/null 2>&1; then
    log "Installing with trizen: ${pkgs[*]}"
    trizen -S --needed --noconfirm "${pkgs[@]}"
    return 0
  fi
  return 1
}

ensure_node() {
  local min="${MIN_NODE:-16.0.0}"
  local v; v="$(get_node_version)"
  if [[ -n "$v" ]]; then
    if ver_ge "$v" "$min"; then
      log "Node.js found: v$v (ok)"
      return 0
    else
      log "Node.js found: v$v (< $min) — upgrading..."
    fi
  else
    log "Node.js not found — installing..."
  fi

  if try_install_pkgs nodejs npm; then
    v="$(get_node_version)"
    if [[ -n "$v" && $(ver_ge "$v" "$min"; echo $?) -eq 0 ]]; then
      log "Node.js ready: v$v"
      return 0
    fi
    warn "Node.js installed but version check failed (got: ${v:-none})."
  fi

  # Fallback: NVM (user-space)
  if [[ -s "$HOME/.nvm/nvm.sh" ]]; then
    # shellcheck disable=SC1090,SC1091
    . "$HOME/.nvm/nvm.sh"
    if command -v nvm >/dev/null 2>&1; then
      log "Using NVM fallback: installing LTS"
      nvm install --lts
      nvm use --lts
      v="$(get_node_version)"
      if [[ -n "$v" && $(ver_ge "$v" "$min"; echo $?) -eq 0 ]]; then
        log "Node.js ready via NVM: v$v"
        return 0
      fi
    fi
  fi

  die "Could not ensure Node.js >= $min automatically. Please install 'nodejs' and re-run."
}
