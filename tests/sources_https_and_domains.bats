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

@test "sources: https and allowed domains pass" {
  local pkgb="$REPO_DIR/tests/fixtures/https_ok_pinned_git/PKGBUILD"
  report_init
  STRICT=0 VERBOSE=0 QUIET=1 rule_sources "$pkgb" 0
  # Should add urls_https_ok and domains_ok
  printf '%s\n' "${REPORT_ITEMS[@]}" | grep -q 'item_source_urls|PASS|urls_https_ok'
  printf '%s\n' "${REPORT_ITEMS[@]}" | grep -q 'item_allowed_domains|PASS|domains_ok'
}

