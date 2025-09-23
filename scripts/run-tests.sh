#!/usr/bin/env bash
# SPDX-License-Identifier: MIT
# Copyright (c) 2025 José Luis López López Prieto <ing.jlllopezp@gmail.com>
# Author GitHub: https://github.com/LuigiD5555
set -euo pipefail

missing=0

if command -v bats >/dev/null 2>&1; then
  bats tests/bats
else
  echo "bats not found. Install bats to run the test suite:" >&2
  echo "  Arch: pacman -S bats" >&2
  echo "  Debian/Ubuntu: apt-get install bats" >&2
  echo "Or run individual checks manually by sourcing lib/* and calling rules." >&2
  missing=1
fi

if command -v node >/dev/null 2>&1; then
  mapfile -t NODE_TEST_FILES < <(find tests/js -name '*.test.mjs' -print 2>/dev/null | sort)
  if [ "${#NODE_TEST_FILES[@]}" -gt 0 ]; then
    node --test "${NODE_TEST_FILES[@]}"
  fi
else
  echo "node not found. Install Node.js (>=18) to run parser tests." >&2
  missing=1
fi

if [ "$missing" -ne 0 ]; then
  exit "$missing"
fi
