#!/usr/bin/env bats

setup() {
  REPO_DIR="$(cd -- "$(dirname -- "${BATS_TEST_FILENAME}")"/.. && pwd)"
  LIB="$REPO_DIR/lib"
  source "$LIB/core/shell_safety.sh"
  source "$LIB/utils/logging.sh"
  source "$LIB/report/render_summary.sh"
  source "$LIB/pkgb/aggregate_pkgb_helpers.sh"
  source "$LIB/pkgb/js_parser_bridge.sh"
  source "$LIB/verify/rules/js_signals_rule.sh"
}

@test "js signals export counts for downstream rules" {
  js_parser_available || skip "Node parser unavailable"
  local pkgb="$REPO_DIR/tests/fixtures/js_signals/PKGBUILD"
  report_init
  unset AUR_JS_SIG_UNPINNED_GIT AUR_JS_SIG_NON_HTTPS AUR_JS_SIG_RED_FLAGS
  STRICT=0 VERBOSE=0 QUIET=1 rule_js_signals "$pkgb" 0
  [ "${AUR_JS_SIG_UNPINNED_GIT:-0}" -eq 1 ]
  [ "${AUR_JS_SIG_NON_HTTPS:-0}" -eq 1 ]
  printf '%s\n' "${REPORT_ITEMS[@]}" | grep -q 'item_js_git_pinning|WARN|js_git_unpinned_warn'
  printf '%s\n' "${REPORT_ITEMS[@]}" | grep -q 'item_js_https|WARN|js_https_warn'
}

@test "js signals mark failures under strict mode" {
  js_parser_available || skip "Node parser unavailable"
  local pkgb="$REPO_DIR/tests/fixtures/js_signals/PKGBUILD"
  report_init
  STRICT=1 VERBOSE=0 QUIET=1 rule_js_signals "$pkgb" 1
  printf '%s\n' "${REPORT_ITEMS[@]}" | grep -q 'item_js_git_pinning|FAIL|js_git_unpinned_fail'
  printf '%s\n' "${REPORT_ITEMS[@]}" | grep -q 'item_js_https|FAIL|js_https_fail'
}
