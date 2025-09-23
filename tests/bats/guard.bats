#!/usr/bin/env bats

load "helpers/common"

setup() {
  setup_test_env
  LIB=$(repo_path lib)
  register_stub yay "$(repo_path tests/stubs/handlers/helper.sh)"
  register_stub paru "$(repo_path tests/stubs/handlers/helper.sh)"
  register_stub pikaur "$(repo_path tests/stubs/handlers/helper.sh)"
  register_stub trizen "$(repo_path tests/stubs/handlers/helper.sh)"
  register_stub pacman "$(repo_path tests/stubs/handlers/helper.sh)"
  register_stub pamac "$(repo_path tests/stubs/handlers/helper.sh)"
  register_stub sudo "$(repo_path tests/stubs/handlers/sudo.sh)"
  source "$LIB/core/shell_safety.sh"
  source "$LIB/guard/logging.sh"
  source "$LIB/guard/paths.sh"
  source "$LIB/guard/flags.sh"
  source "$LIB/guard/helpers_db.sh"
  source "$LIB/guard/runtime.sh"
  source "$LIB/guard/candidates.sh"
  source "$LIB/guard/upgrades.sh"
  source "$LIB/guard/verify.sh"
  guard_init_paths
}

teardown() {
  teardown_test_env
}

@test "guard_consume_wrapper_flags filters helper args" {
  VERIFY_ONLY=0 FAST=0 STRICT=0
  guard_consume_wrapper_flags --verify-only --fast yay -S package --strict
  [ "${VERIFY_ONLY:-0}" -eq 1 ]
  [ "${FAST:-0}" -eq 1 ]
  [ "${STRICT:-0}" -eq 1 ]
  [ "${FILTERED_ARGS[0]}" = "yay" ]
  [ "${FILTERED_ARGS[1]}" = "-S" ]
  [ "${FILTERED_ARGS[2]}" = "package" ]
}

@test "guard_collect_targets_pacman_style extracts package arguments" {
  run guard_collect_targets_pacman_style -S pkg1 pkg2
  [ "$status" -eq 0 ]
  [ "$output" = $'pkg1\npkg2' ]
}

@test "guard_collect_upgrade_targets returns aur packages" {
  local helper
  helper="$(command -v yay)"
  export HELPER_STUB_QUM_OUTPUT=$'aur/foo 1 -> 2\ncommunity/bar 1 -> 2\naur/baz 1 -> 2'
  run guard_collect_upgrade_targets "$helper" pacman
  [ "$status" -eq 0 ]
  echo "# output=$output"
  [[ "$output" == *foo* ]]
  [[ "$output" == *baz* ]]
}

@test "guard_verify_aur_targets verifies explicit list" {
  local helper log stub
  helper="$(command -v yay)"
  log="$TEST_TMPDIR/aur-verify.log"
  stub="$TEST_TMPDIR/aur-verify"
  cat <<'SH' >"$stub"
#!/usr/bin/env bash
set -euo pipefail
printf '%s\n' "$*" >>"$AUR_VERIFY_LOG"
if [[ "$*" == *badpkg* ]]; then
  exit 1
fi
exit 0
SH
  chmod +x "$stub"
  export AUR_VERIFY_LOG="$log"
  export AUR_VERIFY_BIN="$stub"
  export HELPER_STUB_ARGS_LOG="$TEST_TMPDIR/helper.log"
  run guard_verify_aur_targets "$helper" -S goodpkg
  [ "$status" -eq 0 ]
  grep -q -- "--verify-only -- goodpkg" "$log"
}

@test "guard_verify_aur_targets populates ignore list on upgrade" {
  local helper log stub
  helper="$(command -v yay)"
  log="$TEST_TMPDIR/aur-verify.log"
  stub="$TEST_TMPDIR/aur-verify"
  cat <<'SH' >"$stub"
#!/usr/bin/env bash
set -euo pipefail
printf '%s\n' "$*" >>"$AUR_VERIFY_LOG"
if [[ "$*" == *badpkg* ]]; then
  exit 1
fi
exit 0
SH
  chmod +x "$stub"
  export AUR_VERIFY_LOG="$log"
  export AUR_VERIFY_BIN="$stub"
  export HELPER_STUB_QUM_OUTPUT=$'aur/goodpkg 1 -> 2\naur/badpkg 1 -> 2'
  export GUARD_UPGRADE_MODE=1
  guard_verify_aur_targets "$helper" -Syu
  [ "$?" -eq 0 ]
  [ "${SCAN_IGNORE_PKGS:-}" = "badpkg" ]
  grep -q -- "--verify-only -- badpkg" "$log"
}
