#!/usr/bin/env bats

load "helpers/common"

setup() {
  setup_test_env
  repo_root=$(repo_path)
  LIB="$repo_root/lib"
  source "$LIB/guard/logging.sh"
}

teardown() {
  teardown_test_env
}

@test "resolve_pkg returns exact rpc match" {
  source "$LIB/github/derive_candidates_from_repo.sh"
  source "$LIB/aur/search_and_resolve.sh"
  QUIET=1
  aur_plain_rpc_info() { echo '{"resultcount":1,"results":[{"Name":"sample"}]}' ; }
  aur_plain_rpc_info_live() { echo '{"resultcount":1,"results":[{"Name":"sample"}]}' ; }
  aur_plain_exists() { return 0; }
  aur_plain_rpc_search() { return 1; }
  aur_search_name_strict_aur_only() { return 1; }
  yay_exists_any() { return 0; }
  yay_repo_of() { echo aur; }
  run resolve_pkg sample
  [ "$status" -eq 0 ]
  [ "$output" = "sample" ]
}

@test "resolve_pkg prefers candidates from github title" {
  source "$LIB/github/derive_candidates_from_repo.sh"
  source "$LIB/aur/search_and_resolve.sh"
  QUIET=1
  aur_plain_rpc_info() { return 1; }
  aur_plain_rpc_info_live() { return 1; }
  aur_plain_exists() { [[ "$1" == "my-app" ]] && return 0 || return 1; }
  build_candidates_from_github() { printf 'my-app\nmy-app-git\n'; }
  run resolve_pkg https://github.com/example/my-app
  [ "$status" -eq 0 ]
  [ "$output" = "my-app" ]
}
