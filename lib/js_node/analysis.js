// analysis.js — PKGBUILD parsing and risk analysis
import { PATTERNS } from './patterns.js';
import { stripComments, splitItems } from './utils.js';

export function parsePKGBUILD(text) {
  const result = {
    meta: {}, arrays: {}, checksums: {}, functions: {}, sources: [],
    dependencies: { runtime: [], make: [], check: [], optional: [] },
    risks: { unpinnedGitCount: 0, nonHttpsCount: 0, redFlags: [], severity: 'low' },
    architecture: [], conflicts: [], provides: []
  };

  const lines = text.replace(/\r/g, '').split(/\n/);
  let collecting = null; let buffer = ''; let inFunction = false; let currentFunction = null;

  for (let i = 0; i < lines.length; i++) {
    const originalLine = lines[i];
    let line = stripComments(originalLine).trim();
    if (!line) continue;

    const funcMatch = line.match(PATTERNS.functionStart);
    if (funcMatch) { currentFunction = funcMatch[1]; result.functions[currentFunction] = true; inFunction = true; continue; }
    if (inFunction && line === '}') { inFunction = false; currentFunction = null; continue; }

    if (collecting) {
      buffer += ' ' + line;
      if (line.includes(')')) { processArray(collecting, buffer, result); collecting = null; buffer = ''; }
      continue;
    }

    const arrayMatch = line.match(PATTERNS.arrayStart);
    if (arrayMatch) { collecting = arrayMatch[1]; buffer = line; if (line.includes(')')) { processArray(collecting, buffer, result); collecting = null; buffer = ''; } continue; }

    const scalarMatch = line.match(PATTERNS.scalarAssign);
    if (scalarMatch) { processScalarAssignment(scalarMatch[1], scalarMatch[2], result); }

    if (PATTERNS.redFlags.test(line)) {
      result.risks.redFlags.push({ line: i + 1, text: originalLine.trim(), function: currentFunction || 'global', severity: calculateSeverity(line) });
    }
  }

  processSources(result);
  calculateRiskSeverity(result);
  return result;
}

export function processArray(key, content, result) {
  const inner = content.replace(/^[^(]*\(/, '').replace(/\)[^)]*$/, '');
  const items = splitItems(inner);
  result.arrays[key] = items;
  if (key === 'depends') result.dependencies.runtime = items;
  else if (key === 'makedepends') result.dependencies.make = items;
  else if (key === 'checkdepends') result.dependencies.check = items;
  else if (key === 'optdepends') result.dependencies.optional = items;
  else if (key === 'arch') result.architecture = items;
  else if (key === 'conflicts') result.conflicts = items;
  else if (key === 'provides') result.provides = items;
}

export function processScalarAssignment(key, value, result) {
  value = value.trim().replace(/^['"]|['"]$/g, '');
  if (['pkgname','pkgver','pkgrel','epoch','pkgdesc','url','license'].includes(key)) { result.meta[key] = value; }
  if (key.endsWith('sums')) { result.checksums[key] = value; }
}

export function processSources(result) {
  const sources = result.arrays.source || []; const out = []; let unpinned = 0, nonHttps = 0;
  for (const [idx, raw] of sources.entries()) {
    const s = analyzeSource(raw, idx);
    out.push(s); if (s.isGit && !s.pin) unpinned++; if (!s.isHttps) nonHttps++;
  }
  result.sources = out; result.risks.unpinnedGitCount = unpinned; result.risks.nonHttpsCount = nonHttps;
}

export function analyzeSource(rawSource, index) {
  const sourceStr = String(rawSource);
  const sep = sourceStr.indexOf('::');
  const url = sep >= 0 ? sourceStr.slice(sep + 2) : sourceStr;
  const name = sep >= 0 ? sourceStr.slice(0, sep) : `source[${index}]`;
  const scheme = (url.match(PATTERNS.urlScheme) || [])[1] || null;
  const isGit = PATTERNS.gitRepo.test(url);
  const pinMatch = url.match(PATTERNS.gitPin);
  const pin = pinMatch ? { kind: pinMatch[1], value: pinMatch[2] } : null;
  const isHttps = PATTERNS.httpsCheck.test(url);
  let domain = '';
  try { const clean = url.replace(/^git\+/, ''); const u = new URL(clean); domain = u.hostname; }
  catch { const m = url.replace(/^git\+/, '').match(/^[a-zA-Z]+:\/\/([^\/:]+)/); domain = m ? m[1] : 'unknown'; }
  return { raw: rawSource, url, name, scheme, isGit, pin, domain, isHttps, riskLevel: calculateSourceRisk(url, isGit, pin, isHttps) };
}

export function calculateSourceRisk(url, isGit, pin, isHttps) {
  let r = 0; if (isGit && !pin) r += 2; if (!isHttps) r += 1; if (url.includes('github.com') || url.includes('gitlab.com')) r -= 1; return Math.max(0, r);
}

export function calculateSeverity(line) {
  const high = ['rm -rf','dd if=','curl|sh','wget|sh','eval','sudo','su -c'];
  const med  = ['systemctl','useradd','chmod 4','setcap','mount','pkexec'];
  const low = line.toLowerCase();
  if (high.some(p => low.includes(p))) return 'high';
  if (med.some(p => low.includes(p))) return 'medium';
  return 'low';
}

export function calculateRiskSeverity(result) {
  const { redFlags, unpinnedGitCount, nonHttpsCount } = result.risks;
  const high = redFlags.filter(f => f.severity === 'high').length;
  const med  = redFlags.filter(f => f.severity === 'medium').length;
  if (high > 0 || unpinnedGitCount > 2) result.risks.severity = 'high';
  else if (med > 0 || unpinnedGitCount > 0 || nonHttpsCount > 1) result.risks.severity = 'medium';
  else result.risks.severity = 'low';
}

