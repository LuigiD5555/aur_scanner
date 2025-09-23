#!/usr/bin/env bats

load "helpers/common"

setup() {
  setup_test_env
  register_stub git "$(repo_path tests/stubs/handlers/git.sh)"
}

teardown() {
  teardown_test_env
}

_prepare_pkgbuild_tree() {
  local src_root="$TEST_TMPDIR/src"
  mkdir -p "$src_root"
  cp -R "$(repo_path)" "$src_root/aur_verification"
  printf '%s\n' "$src_root"
}

_require_packaging_pkgb() {
  local pkgb="$(repo_path packaging/aur-scanner-git/PKGBUILD)"
  if [[ ! -f "$pkgb" ]]; then
    skip "packaging recipes not available"
  fi
}

@test "pkgver uses git describe when available" {
  local src_root pkgb
  src_root=$(_prepare_pkgbuild_tree)
  export srcdir="$src_root"
  _require_packaging_pkgb
  pkgb="$(repo_path packaging/aur-scanner-git/PKGBUILD)"
  export GIT_STUB_DESCRIBE='v1.2.3-4-gabc123'
  source "$pkgb"
  cd "$srcdir/aur_verification"
  run pkgver
  [ "$status" -eq 0 ]
  [ "$output" = "1.2.3.4.gabc123" ]
}

@test "package installs binaries and docs" {
  local src_root pkgb
  src_root=$(_prepare_pkgbuild_tree)
  export srcdir="$src_root"
  export pkgdir="$TEST_TMPDIR/pkg"
  _require_packaging_pkgb
  pkgb="$(repo_path packaging/aur-scanner-git/PKGBUILD)"
  source "$pkgb"
  cd "$srcdir/aur_verification"
  run package
  [ "$status" -eq 0 ]
  [[ -x "$pkgdir/usr/lib/aur-scanner/bin/scan" ]]
  [[ -x "$pkgdir/usr/bin/scan" ]]
  [[ -f "$pkgdir/usr/share/doc/aur-scanner-git/README.md" ]]
  [[ -f "$pkgdir/usr/share/licenses/aur-scanner-git/LICENSE" ]]
}
