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

@test "sources: non-https warns in non-strict" {
  local pkgb="$REPO_DIR/tests/fixtures/non_https/PKGBUILD"
  report_init
  STRICT=0 VERBOSE=0 QUIET=1 rule_sources "$pkgb" 0
  printf '%s\n' "${REPORT_ITEMS[@]}" | grep -q 'item_source_urls|WARN|urls_https_warn'
}

@test "sources: non-https fails in strict" {
  local pkgb="$REPO_DIR/tests/fixtures/non_https/PKGBUILD"
  report_init
  STRICT=1 VERBOSE=0 QUIET=1 ! rule_sources "$pkgb" 1
  printf '%s\n' "${REPORT_ITEMS[@]}" | grep -q 'item_source_urls|FAIL|urls_https_fail'
}

