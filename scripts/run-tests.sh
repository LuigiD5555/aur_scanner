#!/usr/bin/env bash
# SPDX-License-Identifier: MIT
# Copyright (c) 2025 José Luis López López Prieto <ing.jlllopezp@gmail.com>
# Author GitHub: https://github.com/LuigiD5555

set -euo pipefail
IFS=$'\n\t'

# Exit codes:
# 0  OK
# 10 Test failures
# 11 Tooling/infra error (missing tools, runner no disponible, etc.)

start_ts=$(date +%s)
missing_tools=0
test_failures=0

mkdir -p .ci-artifacts logs || true

echo "==> Environment"
uname -a || true
bash --version | head -n1 || true
if command -v node >/dev/null 2>&1; then
  node --version || true
  command -v npm >/dev/null 2>&1 && npm --version || true
else
  echo "node not found. Install Node.js (>=18) to run parser tests." >&2
  missing_tools=1
fi

echo "==> Running Bats tests (if present)"
if command -v bats >/dev/null 2>&1; then
  if [ -x scripts/run-bats.sh ]; then
    echo "+ scripts/run-bats.sh"
    if ! bash scripts/run-bats.sh; then
      test_failures=1
    fi
  else
    # Busca suites .bats en tests/ o scripts/tests/
    mapfile -t bats_suites < <(git ls-files | grep -E '(^tests/|^scripts/tests/).+\.bats$' || true)
    if [ "${#bats_suites[@]}" -gt 0 ]; then
      echo "+ bats -r ${bats_suites[*]}"
      if ! bats -r "${bats_suites[@]}"; then
        test_failures=1
      fi
    else
      if [ -d tests/bats ]; then
        echo "+ bats tests/bats"
        if ! bats tests/bats; then
          test_failures=1
        fi
      else
        echo "No Bats test files found. Skipping."
      fi
    fi
  fi
else
  echo "bats not found. Install bats (Arch: pacman -S bats | Debian/Ubuntu: apt-get install bats)" >&2
  missing_tools=1
fi

echo "==> Running JS tests (if present)"
if command -v node >/dev/null 2>&1; then
  if [ -f package.json ] && command -v npm >/dev/null 2>&1; then
    # Si hay script test en package.json, úsalo.
    if npm run | grep -qE '(^|\s)test(\s|:)'; then
      echo "+ npm ci && npm test"
      if ! npm ci; then
        echo "npm ci failed" >&2
        exit 11
      fi
      if ! npm test; then
        test_failures=1
      fi
    else
      # Fallback 1: Node test runner nativo (Node>=18)
      mapfile -t NODE_TEST_FILES < <(find tests/js -name '*.test.mjs' -print 2>/dev/null | sort || true)
      if [ "${#NODE_TEST_FILES[@]}" -gt 0 ]; then
        echo "+ node --test ${NODE_TEST_FILES[*]}"
        if ! node --test "${NODE_TEST_FILES[@]}"; then
          test_failures=1
        fi
      else
        # Fallback 2: detecta runners comunes
        if command -v npx >/dev/null 2>&1; then
          if command -v vitest >/dev/null 2>&1 || npx --yes vitest --version >/dev/null 2>&1; then
            echo "+ npx vitest run"
            if ! npx vitest run; then test_failures=1; fi
          elif command -v jest >/dev/null 2>&1 || npx --yes jest --version >/dev/null 2>&1; then
            echo "+ npx jest --ci"
            if ! npx jest --ci; then test_failures=1; fi
          elif command -v mocha >/dev/null 2>&1 || npx --yes mocha --version >/dev/null 2>&1; then
            echo "+ npx mocha"
            if ! npx mocha; then test_failures=1; fi
          else
            echo "No JS test runner found. Skipping."
          fi
        else
          echo "npx not found. Skipping JS tests fallback." >&2
        fi
      fi
    fi
  else
    # Sin package.json: usa el corredor nativo si hay archivos
    mapfile -t NODE_TEST_FILES < <(find tests/js -name '*.test.mjs' -print 2>/dev/null | sort || true)
    if [ "${#NODE_TEST_FILES[@]}" -gt 0 ]; then
      echo "+ node --test ${NODE_TEST_FILES[*]}"
      if ! node --test "${NODE_TEST_FILES[@]}"; then
        test_failures=1
      fi
    else
      echo "No JS tests found. Skipping."
    fi
  fi
fi

end_ts=$(date +%s)
echo "==> Test suite finished in $((end_ts - start_ts))s"

# Prioridad de salidas: tooling > test failures > OK
if [ "$missing_tools" -ne 0 ]; then
  exit 11
fi
if [ "$test_failures" -ne 0 ]; then
  exit 10
fi
exit 0
