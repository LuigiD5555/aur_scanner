#!/usr/bin/env bats

setup() {
  REPO_DIR="$(cd -- "$(dirname -- "${BATS_TEST_FILENAME}")"/.. && pwd)"
  LIB="$REPO_DIR/lib"
  source "$LIB/core/shell_safety.sh"
  source "$LIB/utils/logging.sh"
  source "$LIB/report/render_summary.sh"
  source "$LIB/pkgb/aggregate_pkgb_helpers.sh"
  source "$LIB/verify/verification_rules_loader.sh"
  source "$LIB/verify/aur_verification_orchestrator.sh"
}

@test "vcs pinning: unpinned warns non-strict" {
  local pkgb="$REPO_DIR/tests/fixtures/git_unpinned/PKGBUILD"
  report_init
  STRICT=0 VERBOSE=0 QUIET=1
  local status=0
  rule_vcs_pinning "$pkgb" 0 || status=$?
  [ "$status" -eq 0 ]
  printf '%s\n' "${REPORT_ITEMS[@]}" | grep -q 'item_vcs_pinning|WARN|vcs_unpinned_warn'
}

@test "vcs pinning: unpinned fails strict" {
  local pkgb="$REPO_DIR/tests/fixtures/git_unpinned/PKGBUILD"
  report_init
  STRICT=1 VERBOSE=0 QUIET=1
  local status=0
  rule_vcs_pinning "$pkgb" 1 || status=$?
  [ "$status" -ne 0 ]
  printf '%s\n' "${REPORT_ITEMS[@]}" | grep -q 'item_vcs_pinning|FAIL|vcs_unpinned_fail'
}
