#!/usr/bin/env bats

setup() {
  REPO_DIR="$(cd -- "$(dirname -- "${BATS_TEST_FILENAME}")"/.. && pwd)"
  LIB="$REPO_DIR/lib"
  source "$LIB/core/shell_safety.sh"
  source "$LIB/utils/logging.sh"
  source "$LIB/pkgb/aggregate_pkgb_helpers.sh"
  source "$LIB/verify/verification_rules_loader.sh"
  source "$LIB/verify/aur_verification_orchestrator.sh"
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
