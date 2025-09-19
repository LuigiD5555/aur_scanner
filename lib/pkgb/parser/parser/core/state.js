// SPDX-License-Identifier: MIT
// Copyright (c) 2025 José Luis López López Prieto <ing.jlllopezp@gmail.com>
// Author GitHub: https://github.com/LuigiD5555
// state.js — creates the initial result structure for PKGBUILD parsing

export function createInitialResult() {
  return {
    meta: {},
    arrays: {},
    checksums: {},
    functions: {},
    sources: [],
    dependencies: { runtime: [], make: [], check: [], optional: [] },
    risks: { unpinnedGitCount: 0, nonHttpsCount: 0, redFlags: [], severity: 'low' },
    architecture: [],
    conflicts: [],
    provides: []
  };
}
