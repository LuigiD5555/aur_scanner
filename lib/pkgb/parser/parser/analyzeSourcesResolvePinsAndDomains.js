// analyzeSourcesResolvePinsAndDomains.js — analyzes PKGBUILD source entries,
// resolves pins/https scheme, extracts domains, and assigns risk levels
import { PATTERNS } from '../patterns/compileRegexPatterns.js';

export function processSources(result) {
  const sources = result.arrays.source ?? [];
  const out = [];
  let unpinned = 0;
  let nonHttps = 0;
  for (const [idx, raw] of sources.entries()) {
    const s = analyzeSource(raw, idx);
    out.push(s);
    if (s.isGit && !s.pin) unpinned++;
    if (!s.isHttps) nonHttps++;
  }
  result.sources = out;
  result.risks.unpinnedGitCount = unpinned;
  result.risks.nonHttpsCount = nonHttps;
}

export function analyzeSource(rawSource, index) {
  const sourceStr = String(rawSource);
  const sep = sourceStr.indexOf('::');
  const url = sep >= 0 ? sourceStr.slice(sep + 2) : sourceStr;
  const name = sep >= 0 ? sourceStr.slice(0, sep) : `source[${index}]`;
  const scheme = (url.match(PATTERNS.urlScheme) ?? [])[1] ?? null;
  const isGit = PATTERNS.gitRepo.test(url);
  const pinMatch = url.match(PATTERNS.gitPin);
  const pin = pinMatch ? { kind: pinMatch[1], value: pinMatch[2] } : null;
  const isHttps = PATTERNS.httpsCheck.test(url);
  let domain = '';
  try {
    const clean = url.replace(/^git\+/, '');
    const u = new URL(clean);
    domain = u.hostname;
  } catch {
    const m = url.replace(/^git\+/, '').match(/^[a-zA-Z]+:\/\/([^\/:]+)/);
    domain = m ? m[1] : 'unknown';
  }
  return {
    raw: rawSource,
    url,
    name,
    scheme,
    isGit,
    pin,
    domain,
    isHttps,
    riskLevel: calculateSourceRisk(url, isGit, pin, isHttps)
  };
}

export function calculateSourceRisk(url, isGit, pin, isHttps) {
  let r = 0;
  if (isGit && !pin) r += 2;
  if (!isHttps) r += 1;
  if (url.includes('github.com') || url.includes('gitlab.com')) r -= 1;
  return Math.max(0, r);
}

