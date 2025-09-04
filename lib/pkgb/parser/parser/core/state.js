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

