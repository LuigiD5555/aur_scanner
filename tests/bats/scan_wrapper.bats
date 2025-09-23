#!/usr/bin/env bats

load "helpers/common"

setup() {
  setup_test_env
  export HELPER_STUB_ARGS_LOG="$TEST_TMPDIR/helper.log"
  register_stub yay "$(repo_path tests/stubs/handlers/helper.sh)"
  register_stub sudo "$(repo_path tests/stubs/handlers/sudo.sh)"
  export SCAN_LIBDIR="$(repo_path lib)"
  export SCAN_REAL_YAY="$(command -v yay)"
  cp "$(repo_path bin/scan)" "$TEST_TMPDIR/scan"
  cp "$(repo_path bin/scan-shim)" "$TEST_TMPDIR/scan-shim"
  chmod +x "$TEST_TMPDIR/scan" "$TEST_TMPDIR/scan-shim"
  export TEST_SCAN_BIN="$TEST_TMPDIR/scan"
  export TEST_SCAN_SHIM="$TEST_TMPDIR/scan-shim"
  # aur-verify stub script per test (set in each case)
}

teardown() {
  teardown_test_env
}

_create_aur_verify_stub() {
  local path="$TEST_TMPDIR/aur-verify"
  cat <<'SH' >"$path"
#!/usr/bin/env bash
set -euo pipefail
printf '%s\n' "$*" >>"$AUR_VERIFY_LOG"
  for arg in "$@"; do
  if [[ "$arg" == *badpkg* ]]; then
    exit 1
  fi
done
exit 0
SH
  chmod +x "$path"
  export AUR_VERIFY_BIN="$path"
  export AUR_VERIFY_LOG="$TEST_TMPDIR/aur-verify.log"
  : >"$AUR_VERIFY_LOG"
  : >"$HELPER_STUB_ARGS_LOG"
  unset SCAN_IGNORE_PKGS
}

@test "scan --verify-only avoids helper delegation" {
  _create_aur_verify_stub
  run bash "$TEST_SCAN_BIN" yay --verify-only -S goodpkg
  [ "$status" -eq 0 ]
  grep -q -- "--verify-only" "$AUR_VERIFY_LOG"
  [ ! -s "$HELPER_STUB_ARGS_LOG" ]
}

@test "scan delegates to helper after verification" {
  _create_aur_verify_stub
  run bash "$TEST_SCAN_BIN" yay -S goodpkg
  [ "$status" -eq 0 ]
  grep -q -- "--verify-only -- goodpkg" "$AUR_VERIFY_LOG"
  grep -q "yay -S goodpkg" "$HELPER_STUB_ARGS_LOG"
}

@test "scan-shim handles helper symlink invocations" {
  _create_aur_verify_stub
  local shim_dir="$TEST_TMPDIR/shims"
  mkdir -p "$shim_dir"
  cp "$TEST_SCAN_BIN" "$shim_dir/scan"
  cp "$TEST_SCAN_SHIM" "$shim_dir/scan-shim"
  chmod +x "$shim_dir/scan" "$shim_dir/scan-shim"
  ln -s "$shim_dir/scan-shim" "$shim_dir/yay"
  PATH="$shim_dir:$PATH"
  register_stub yay "$(repo_path tests/stubs/handlers/helper.sh)"
  run yay --verify-only -S goodpkg
  [ "$status" -eq 0 ]
  grep -q -- "--verify-only -- goodpkg" "$AUR_VERIFY_LOG"
  [ ! -s "$HELPER_STUB_ARGS_LOG" ]
}
