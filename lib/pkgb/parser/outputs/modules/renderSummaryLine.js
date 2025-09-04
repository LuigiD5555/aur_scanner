// renderSummaryLine.js — one-line summary output

export function printSummary(obj) {
  const { meta, risks, sources, functions } = obj;
  const funcCount = Object.keys(functions || {}).length;
  console.log(`PKGBUILD: ${meta.pkgname || '(unknown)'} ${meta.pkgver || '(unknown)'} — sources:${sources.length} git-unpinned:${risks.unpinnedGitCount} non-https:${risks.nonHttpsCount} redflags:${risks.redFlags.length} severity:${risks.severity} functions:${funcCount}`);
}

