# SPDX-License-Identifier: MIT
# Copyright (c) 2025 José Luis López López Prieto <ing.jlllopezp@gmail.com>
# Author GitHub: https://github.com/LuigiD5555
# shellcheck shell=bash
# Common helpers: logging, usage, banner, shell/ PATH utilities

usage() {
  cat <<'EOF'
Usage: scripts/install-scanner.sh [--user|--system]

Options:
  --user          Install to ~/.local/bin and stage runtime under ~/.local/lib/scan (default)
  --system        Install to /usr/local/bin and stage runtime under /usr/local/lib/scan (requires root)

This will:
  - Copy runtime files (bin/*, lib/**) to an executable prefix (handles NTFS/noexec).
  - Set +x on files with shebang (#!), 0644 otherwise.
  - Create launcher symlink "scan" and helper symlinks (yay/paru/pikaur/trizen/pamac) pointing to the staged wrapper.
  - Ensure ~/.local/bin is at the front of PATH (zsh/bash).
  - Ensure Node.js is available (>= 16). If missing/outdated, tries to install it.

Notes:
  - The wrapper binary in this repo is "bin/scan" (without .sh). If your repo uses a different filename,
    adjust GUARD_BASENAME in lib/install/env.sh
EOF
}

print_banner() {
  cat <<'ASCII'
       ,----,.       ,----,.       ,----,.       ,----,. 
     ,'¨¨¨,'5|     ,'¨¨¨,'5|     ,'¨¨¨,'5|     ,'¨¨¨,'5| 
   ,'¨¨¨.'555|   ,'¨¨¨.'555|   ,'¨¨¨.'555|   ,'¨¨¨.'555| 
 ,----.'5555.' ,----.'5555.' ,----.'5555.' ,----.'5555.' 
 |¨¨¨¨|555.'   |¨¨¨¨|555.'   |¨¨¨¨|555.'   |¨¨¨¨|555.'   
 :¨¨¨¨:55|--,  :¨¨¨¨:55|--,  :¨¨¨¨:55|--,  :¨¨¨¨:55|--,  
 :¨▗▄▖|▗▖;▗▖▗▄▄▖¨¨▗▄▄▖5▗▄▄▖\▗▄▖¨▗▖|5▗▖▗▖5\▗▖▗▄▄▄▖▗▄▄▖'5\ 
 |▐▌¨▐▌▐▌5▐▌▐▌ ▐▌▐▌¨|5▐▌555▐▌|▐▌▐▛▚▖▐▌▐▛▚▖▐▌▐▌¨¨|▐▌5▐▌5|
 `▐▛▀▜▌▐▌\▐▌▐▛▀▚▖-▝▀▚▖▐▌555▐▛▀▜▌▐▌'▝▜▌▐▌5▝▜▌▐▛▀▀▘▐▛▀▚▖5; 
  ▐▌ ▐▌▝▚▄▞▘▐▌ ▐▌▗▄▄▞▘▝▚▄▄▖▐▌ ▐▌▐▌ \▐▌▐▌5|▐▌▐▙▄▄▖▐▌ ▐▌5| 
 /¨¨¨/\/  /55: /¨¨¨/\/  /55: /¨¨¨/\/  /55: /¨¨¨/\/  /55: 
/___/55',-555./___/55',-555./___/55',-555./___/55',-555. 
\'''\5555555; \ ''\5555555; \ ''\5555555; \ ''\5555555;  
 \¨¨¨\5555.'   \¨¨¨\5555.'   \¨¨¨\5555.'   \¨¨¨\5555.'   
  `--`-,-'      `--`-,-'      `--`-,-'      `--`-,-'     
ASCII
  echo
}

log()  { printf '[install-scanner] %s\n' "$*"; }
warn() { printf '[install-scanner][warn] %s\n' "$*" >&2; }
die()  { printf '[install-scanner][error] %s\n' "$*" >&2; exit 1; }

detect_shell() {
  if [[ -n "${ZSH_VERSION-}" ]] || [[ "${SHELL-}" == *"zsh" ]]; then
    echo "zsh"
  else
    echo "bash"
  fi
}

ensure_path_line() {
  local file="$1"
  local line='export PATH="$HOME/.local/bin:$PATH"'
  [[ -f "$file" ]] || : >"$file"
  if ! grep -Fqx "$line" "$file" 2>/dev/null; then
    printf '%s\n' "$line" >> "$file"
    log "Added ~/.local/bin to PATH in $file"
  fi
}
