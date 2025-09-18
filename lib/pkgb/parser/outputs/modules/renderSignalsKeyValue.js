// SPDX-License-Identifier: MIT
// Copyright (c) 2025 José Luis López López Prieto
// Author GitHub: https://github.com/LuigiD5555
// renderSignalsKeyValue.js — key=value signal output for shell integration

export function printSignals(obj) {
  const signals = {
    pkgname: obj.meta.pkgname || '',
    pkgver: obj.meta.pkgver || '',
    sources: obj.sources.length,
    unpinnedGit: obj.risks.unpinnedGitCount,
    nonHttps: obj.risks.nonHttpsCount,
    redFlags: obj.risks.redFlags.length,
    severity: obj.risks.severity,
    functions: Object.keys(obj.functions || {}).length
  };
  Object.entries(signals).forEach(([k, v]) => console.log(`${k}=${v}`));
}
