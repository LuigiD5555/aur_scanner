#!/usr/bin/env bats

load "helpers/common"

setup() {
  setup_test_env
  register_stub node "$(repo_path tests/stubs/handlers/node.sh)"
  register_stub sudo "$(repo_path tests/stubs/handlers/sudo.sh)"
  register_stub pacman "$(repo_path tests/stubs/handlers/helper.sh)"
  register_stub yay "$(repo_path tests/stubs/handlers/helper.sh)"
  register_stub paru "$(repo_path tests/stubs/handlers/helper.sh)"
  register_stub pikaur "$(repo_path tests/stubs/handlers/helper.sh)"
  register_stub trizen "$(repo_path tests/stubs/handlers/helper.sh)"
  register_stub pamac "$(repo_path tests/stubs/handlers/helper.sh)"
  export NODE_STUB_VERSION=18.12.1
}

teardown() {
  teardown_test_env
}

@test "install-scanner --user stages runtime and symlinks" {
  run bash "$(repo_path scripts/install-scanner.sh)" --user
  [ "$status" -eq 0 ]
  [[ -x "$HOME/.local/lib/scan/bin/scan" ]]
  [[ -f "$HOME/.local/lib/scan/lib/guard/logging.sh" ]]
  [[ -L "$HOME/.local/bin/scan" ]]
  [[ -L "$HOME/.local/bin/yay" ]]
  if [[ -f "$HOME/.profile" ]]; then
    grep -Fq 'export PATH="$HOME/.local/bin:$PATH"' "$HOME/.profile"
  fi
  if [[ -f "$HOME/.bashrc" ]]; then
    grep -Fq 'export PATH="$HOME/.local/bin:$PATH"' "$HOME/.bashrc"
  fi
  if [[ -f "$HOME/.zprofile" ]]; then
    grep -Fq 'export PATH="$HOME/.local/bin:$PATH"' "$HOME/.zprofile"
  fi
  if [[ -f "$HOME/.zshrc" ]]; then
    grep -Fq 'export PATH="$HOME/.local/bin:$PATH"' "$HOME/.zshrc"
  fi
}

@test "uninstall-scanner removes staged runtime" {
  run bash "$(repo_path scripts/install-scanner.sh)" --user
  [ "$status" -eq 0 ]
  run bash "$(repo_path scripts/uninstall-scanner.sh)" --user
  [ "$status" -eq 0 ]
  [[ ! -d "$HOME/.local/lib/scan" ]]
  [[ -L "$HOME/.local/bin/scan" ]]
  [[ ! -e "$HOME/.local/bin/yay" ]]
}
