#!/usr/bin/env bash
# Common helper utilities for Bats tests

_common_resolve_repo_root() {
  if [[ -n "${TEST_REPO_ROOT:-}" ]]; then
    printf '%s\n' "$TEST_REPO_ROOT"
    return
  fi
  local origin dir
  origin="${BATS_TEST_DIRNAME:-$(dirname -- "${BASH_SOURCE[0]}")}" 
  dir=$(cd -- "$origin" && pwd)
  while [[ "$dir" != "/" && ! -d "$dir/.git" ]]; do
    dir="$(dirname -- "$dir")"
  done
  export TEST_REPO_ROOT="$dir"
  printf '%s\n' "$dir"
}

setup_test_env() {
  local repo_root
  repo_root=$(_common_resolve_repo_root)
  export TEST_TMPDIR="$(mktemp -d)"
  export HOME="$TEST_TMPDIR/home"
  mkdir -p "$HOME"
  local stub_src="$repo_root/tests/stubs/bin"
  local stub_dst="$TEST_TMPDIR/bin"
  mkdir -p "$stub_dst"
  cp "$stub_src/__stub.sh" "$stub_dst/__stub.sh"
  chmod +x "$stub_dst/__stub.sh"
  local name
  for name in $(cd "$stub_src" && find . -maxdepth 1 -type l -printf '%f\n'); do
    ln -sf __stub.sh "$stub_dst/$name"
  done
  export PATH="$stub_dst:$PATH"
  export STUB_REGISTRY_DIR="$TEST_TMPDIR/stubs"
  mkdir -p "$STUB_REGISTRY_DIR"
  unset STUB_DEFAULT
  for var in $(env | grep -E '^STUB_[A-Z0-9_]*=' | cut -d= -f1); do
    unset "$var"
  done
}

teardown_test_env() {
  if [[ -n "${TEST_TMPDIR:-}" && -d "$TEST_TMPDIR" ]]; then
    rm -rf "$TEST_TMPDIR"
  fi
}

register_stub() {
  local cmd="$1" handler="$2" upper
  upper=$(printf '%s' "$cmd" | tr '[:lower:]-' '[:upper:]_')
  export "STUB_${upper}=$handler"
}

clear_stub() {
  local cmd="$1" upper
  upper=$(printf '%s' "$cmd" | tr '[:lower:]-' '[:upper:]_')
  unset "STUB_${upper}"
}

repo_path() {
  local repo_root
  repo_root=$(_common_resolve_repo_root)
  printf '%s/%s\n' "$repo_root" "${1:-}"
}

fixture_path() {
  local repo_root
  repo_root=$(_common_resolve_repo_root)
  printf '%s/tests/fixtures/%s\n' "$repo_root" "${1:-}"
}

make_temp_dir() {
  local dir
  dir="${TEST_TMPDIR:-$(mktemp -d)}/$1"
  mkdir -p "$dir"
  printf '%s\n' "$dir"
}

with_clean_report() {
  report_init
}

assert_report_has() {
  local needle="$1"
  printf '%s\n' "${REPORT_ITEMS[@]}" | grep -F -- "$needle"
}
