#!/usr/bin/env bash
set -euo pipefail

if command -v bats >/dev/null 2>&1; then
  bats tests
else
  echo "bats not found. Install bats to run the test suite:"
  echo "  Arch: pacman -S bats"
  echo "  Debian/Ubuntu: apt-get install bats"
  echo "Or run individual checks manually by sourcing lib/* and calling rules."
  exit 127
fi

