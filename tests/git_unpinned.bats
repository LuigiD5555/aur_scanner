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

@test "vcs pinning: unpinned warns non-strict" {
  local pkgb="$REPO_DIR/tests/fixtures/git_unpinned/PKGBUILD"
  report_init
  STRICT=0 VERBOSE=0 QUIET=1 rule_vcs_pinning "$pkgb" 0
  printf '%s\n' "${REPORT_ITEMS[@]}" | grep -q 'item_vcs_pinning|WARN|vcs_unpinned_warn'
}

@test "vcs pinning: unpinned fails strict" {
  local pkgb="$REPO_DIR/tests/fixtures/git_unpinned/PKGBUILD"
  report_init
  STRICT=1 VERBOSE=0 QUIET=1 ! rule_vcs_pinning "$pkgb" 1
  printf '%s\n' "${REPORT_ITEMS[@]}" | grep -q 'item_vcs_pinning|FAIL|vcs_unpinned_fail'
}

