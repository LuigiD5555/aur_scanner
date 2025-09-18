#!/usr/bin/env bats

setup() {
  REPO_DIR="$(cd -- "$(dirname -- "${BATS_TEST_FILENAME}")"/.. && pwd)"
  LIB="$REPO_DIR/lib"
  source "$LIB/core/shell_safety.sh"
  source "$LIB/utils/logging.sh"
  source "$LIB/report/render_summary.sh"
  source "$LIB/pkgb/js_parser_bridge.sh"
  source "$LIB/pkgb/aggregate_pkgb_helpers.sh"
  source "$LIB/verify/verification_rules_loader.sh"
  source "$LIB/verify/aur_verification_orchestrator.sh"
}

@test "sources: https and allowed domains pass" {
  local pkgb="$REPO_DIR/tests/fixtures/https_ok_pinned_git/PKGBUILD"
  report_init
  STRICT=0 VERBOSE=0 QUIET=1
  local status=0
  rule_sources "$pkgb" 0 || status=$?
  [ "$status" -eq 0 ]
  # Should add urls_https_ok and domains_ok
  printf '%s\n' "${REPORT_ITEMS[@]}" | grep -q 'item_source_urls|PASS|urls_https_ok'
  printf '%s\n' "${REPORT_ITEMS[@]}" | grep -q 'item_allowed_domains|PASS|domains_ok'
}
