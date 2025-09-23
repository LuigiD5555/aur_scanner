#!/usr/bin/env bats

load "helpers/common"

setup() {
  setup_test_env
}

teardown() {
  teardown_test_env
}

@test "validate-sources succeeds on repo" {
  run bash "$(repo_path scripts/validate-sources.sh)"
  [ "$status" -eq 0 ]
}
