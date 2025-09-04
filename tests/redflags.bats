#!/usr/bin/env bats

setup() {
  REPO_DIR="$(cd -- "$(dirname -- "${BATS_TEST_FILENAME}")"/.. && pwd)"
  LIB="$REPO_DIR/lib"
  source "$LIB/common.sh"
  source "$LIB/log.sh"
  source "$LIB/pkgb.sh"
  source "$LIB/verify_rules.sh"
  source "$LIB/verify.sh"
}

@test "red flags: warn non-strict" {
  local pkgb="$REPO_DIR/tests/fixtures/redflags/PKGBUILD"
  report_init
  STRICT=0 VERBOSE=0 QUIET=1 rule_red_flags "$pkgb" 0 || true
  printf '%s\n' "${REPORT_ITEMS[@]}" | grep -q 'item_red_flags|WARN|redflags_warn'
}

@test "red flags: fail strict" {
  local pkgb="$REPO_DIR/tests/fixtures/redflags/PKGBUILD"
  report_init
  STRICT=1 VERBOSE=0 QUIET=1 ! rule_red_flags "$pkgb" 1
  printf '%s\n' "${REPORT_ITEMS[@]}" | grep -q 'item_red_flags|FAIL|redflags_fail'
}

