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

@test "verifysource: skip in verify-only mode" {
  local dir; dir="$(mktemp -d)"; touch "$dir/PKGBUILD"
  report_init
  rule_verifysource "$dir" verify-only 0
  printf '%s\n' "${REPORT_ITEMS[@]}" | grep -q 'item_makepkg_verifysource|SKIP|verifysource_skip_verifyonly'
}

@test "verifysource: skip in fast mode" {
  local dir; dir="$(mktemp -d)"; touch "$dir/PKGBUILD"
  report_init
  rule_verifysource "$dir" fast 0
  printf '%s\n' "${REPORT_ITEMS[@]}" | grep -q 'item_makepkg_verifysource|SKIP|verifysource_skip_fast'
}
