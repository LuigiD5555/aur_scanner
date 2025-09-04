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
/*
  License: CC BY-NC-SA 4.0 (https://creativecommons.org/licenses/by-nc-sa/4.0/)
  Copyright (c) 2025 José Luis López López Prieto
*/
