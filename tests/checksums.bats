#!/usr/bin/env bats

setup() {
  REPO_DIR="$(cd -- "$(dirname -- "${BATS_TEST_FILENAME}")"/.. && pwd)"
  LIB="$REPO_DIR/lib"
  WORKDIR="$(mktemp -d)"
  source "$LIB/core/shell_safety.sh"
  source "$LIB/utils/logging.sh"
  source "$LIB/report/render_summary.sh"
  source "$LIB/pkgb/aggregate_pkgb_helpers.sh"
  source "$LIB/verify/rules/checksums_rule.sh"
}

teardown() {
  rm -rf "$WORKDIR"
}

_copy_fixture() {
  local fixture="$1"
  cp "$fixture" "$WORKDIR/PKGBUILD"
}

@test "checksum rule skips rewrite when verify-only" {
  local pkgb_fixture="$REPO_DIR/tests/fixtures/checksums/PKGBUILD"
  _copy_fixture "$pkgb_fixture"
  report_init
  VERIFY_ONLY=1 FAST=0 STRICT=0 QUIET=1 rule_checksums "$WORKDIR/PKGBUILD" "$WORKDIR" 0 0
  printf '%s\n' "${REPORT_ITEMS[@]}" | grep -q 'item_checksums|WARN|sum_autofixed_skipverifyonly'
}

@test "checksum rule attempts rewrite when verify-only disabled" {
  local pkgb_fixture="$REPO_DIR/tests/fixtures/checksums/PKGBUILD"
  _copy_fixture "$pkgb_fixture"
  report_init
  VERIFY_ONLY=0 FAST=0 STRICT=0 QUIET=1 rule_checksums "$WORKDIR/PKGBUILD" "$WORKDIR" 0 0
  printf '%s\n' "${REPORT_ITEMS[@]}" | grep -q 'item_checksums|WARN|sum_autofixed_fail'
}
