#!/usr/bin/env bats

load "helpers/common"

setup() {
  setup_test_env
  LIB=$(repo_path lib)
  register_stub makepkg "$(repo_path tests/stubs/handlers/makepkg.sh)"
  source "$LIB/core/shell_safety.sh"
  source "$LIB/guard/logging.sh"
  source "$LIB/report/render_summary.sh"
  source "$LIB/pkgb/aggregate_pkgb_helpers.sh"
  source "$LIB/rules/checksums_rule.sh"
  source "$LIB/rules/sources_rule.sh"
  source "$LIB/rules/vcs_pinning_rule.sh"
  source "$LIB/rules/redflags_rule.sh"
  source "$LIB/rules/verifysource_rule.sh"
}

teardown() {
  teardown_test_env
}

@test "rule_checksums skips rewrite in verify-only mode" {
  local pkgb
  pkgb="$(fixture_path checksums/PKGBUILD)"
  cp "$pkgb" "$TEST_TMPDIR/PKGBUILD"
  with_clean_report
  VERIFY_ONLY=1 FAST=0 STRICT=0 QUIET=1 rule_checksums "$TEST_TMPDIR/PKGBUILD" "$TEST_TMPDIR" 0 0
  assert_report_has 'item_checksums|WARN|sum_autofixed_skipverifyonly'
}

@test "rule_checksums rewrites weak sums to sha256" {
  local pkgb dest
  pkgb="$(fixture_path checksums/PKGBUILD)"
  dest="$TEST_TMPDIR/pkgb"
  mkdir -p "$dest"
  cp "$pkgb" "$dest/PKGBUILD"
  export MAKEPKG_GENERATE_OUTPUT=$'sha256sums=(\'deadbeef\')'
  with_clean_report
  VERIFY_ONLY=0 FAST=0 STRICT=0 QUIET=1 rule_checksums "$dest/PKGBUILD" "$dest" 0 0
  assert_report_has 'item_checksums|PASS|sum_autofixed_ok'
  grep -q "sha256sums=('deadbeef')" "$dest/PKGBUILD"
}

@test "rule_checksums fails under strict mode" {
  local pkgb
  pkgb="$(fixture_path checksums/PKGBUILD)"
  cp "$pkgb" "$TEST_TMPDIR/PKGBUILD"
  with_clean_report
  STRICT=1 FAST=0 VERIFY_ONLY=0 QUIET=1
  set +e
  rule_checksums "$TEST_TMPDIR/PKGBUILD" "$TEST_TMPDIR" 1 0
  status=$?
  set -e
  [ "$status" -ne 0 ]
  assert_report_has 'item_checksums|FAIL|sum_weak_fail'
}

@test "rule_sources detects non-https" {
  local pkgb
  pkgb="$(fixture_path non_https/PKGBUILD)"
  with_clean_report
  STRICT=0 QUIET=1 rule_sources "$pkgb" 0
  assert_report_has 'item_source_urls|WARN|urls_https_warn'
}

@test "rule_sources enforces strict failure for non-https" {
  local pkgb
  pkgb="$(fixture_path non_https/PKGBUILD)"
  with_clean_report
  set +e
  rule_sources "$pkgb" 1
  status=$?
  set -e
  [ "$status" -ne 0 ]
  assert_report_has 'item_source_urls|FAIL|urls_https_fail'
}

@test "rule_sources allows https entries with Bash substring syntax" {
  local pkgb
  pkgb="$(fixture_path https_substring/PKGBUILD)"
  with_clean_report
  ALLOWED_DOMAINS='.*'
  STRICT=0 QUIET=1 rule_sources "$pkgb" 0
  assert_report_has 'item_source_urls|PASS|urls_https_ok'
  assert_report_has 'item_allowed_domains|PASS|domains_ok'
}

@test "rule_vcs_pinning warns when unpinned" {
  local pkgb
  pkgb="$(fixture_path git_unpinned/PKGBUILD)"
  with_clean_report
  rule_vcs_pinning "$pkgb" 0
  [ "$?" -eq 0 ]
  assert_report_has 'item_vcs_pinning|WARN|vcs_unpinned_warn'
}

@test "rule_red_flags escalates in strict" {
  local pkgb
  pkgb="$(fixture_path redflags/PKGBUILD)"
  with_clean_report
  set +e
  rule_red_flags "$pkgb" 1
  status=$?
  set -e
  [ "$status" -ne 0 ]
  assert_report_has 'item_red_flags|FAIL|redflags_fail'
}

@test "rule_verifysource skips verify-only" {
  local dir
  dir="$(make_temp_dir verifysource)"
  touch "$dir/PKGBUILD"
  with_clean_report
  rule_verifysource "$dir" verify-only 0
  assert_report_has 'item_makepkg_verifysource|SKIP|verifysource_skip_verifyonly'
}

@test "rule_verifysource records failure when makepkg fails" {
  local dir
  dir="$(make_temp_dir verifysource-fail)"
  touch "$dir/PKGBUILD"
  export MAKEPKG_VERIFY_STATUS=1
  with_clean_report
  set +e
  rule_verifysource "$dir" full 1
  status=$?
  set -e
  [ "$status" -ne 0 ]
  assert_report_has 'item_makepkg_verifysource|FAIL|verifysource_fail_strict'
}
