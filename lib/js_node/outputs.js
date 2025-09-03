// outputs.js — formatters for CLI
import { colorize } from './colors.js';

export function printDetailedAnalysis(obj) {
  const meta = obj.meta; const risks = obj.risks; const deps = obj.dependencies;
  console.log(colorize('\nPKGBUILD Analysis:', 'bold'));
  console.log(`Package: ${colorize(meta.pkgname || '(unknown)', 'cyan')} ${colorize(meta.pkgver || '(unknown)', 'blue')}`);
  if (meta.pkgdesc) console.log(`Description: ${colorize(meta.pkgdesc, 'gray')}`);
  if (meta.url) console.log(`URL: ${colorize(meta.url, 'blue')}`);
  console.log(`Architecture: ${colorize((obj.architecture || []).join(', ') || 'any', 'magenta')}`);
  const funcList = Object.keys(obj.functions || {});
  if (funcList.length > 0) console.log(`Functions: ${colorize(funcList.join(', '), 'green')}`);

  console.log(colorize('\nDependencies:', 'bold'));
  console.log(`  Runtime: ${colorize(String(deps.runtime.length), 'cyan')} packages`);
  console.log(`  Build: ${colorize(String(deps.make.length), 'yellow')} packages`);
  console.log(`  Check: ${colorize(String(deps.check.length), 'blue')} packages`);
  console.log(`  Optional: ${colorize(String(deps.optional.length), 'gray')} packages`);
  if (deps.runtime.length > 0) console.log(`    Runtime deps: ${deps.runtime.slice(0, 5).join(', ')}${deps.runtime.length > 5 ? '...' : ''}`);

  console.log(colorize('\nSources:', 'bold') + ` ${obj.sources.length}`);
  obj.sources.forEach((src, i) => {
    const riskColor = src.riskLevel > 1 ? 'red' : src.riskLevel > 0 ? 'yellow' : 'green';
    const pinStatus = src.isGit ? (src.pin ? `${src.pin.kind}=${src.pin.value.slice(0, 8)}` : colorize('unpinned', 'red')) : '-';
    const httpsStatus = src.isHttps ? colorize('https', 'green') : colorize('non-https', 'yellow');
    console.log(`  [${i}] ${colorize(src.name, 'cyan')} -> ${colorize(src.domain || 'unknown', 'blue')}`);
    console.log(`      Type: ${src.isGit ? colorize('git', 'magenta') : colorize(src.scheme || 'file', 'gray')} | Pin: ${pinStatus} | ${httpsStatus} | Risk: ${colorize(String(src.riskLevel), riskColor)}`);
  });

  const sevColor = risks.severity === 'high' ? 'red' : risks.severity === 'medium' ? 'yellow' : 'green';
  console.log(colorize('\nSecurity Analysis:', 'bold') + ` (${colorize(risks.severity, sevColor)})`);
  console.log(`  Git unpinned: ${colorize(String(risks.unpinnedGitCount), risks.unpinnedGitCount > 0 ? 'yellow' : 'green')}`);
  console.log(`  Non-HTTPS sources: ${colorize(String(risks.nonHttpsCount), risks.nonHttpsCount > 0 ? 'yellow' : 'green')}`);
  console.log(`  Security flags: ${colorize(String(risks.redFlags.length), risks.redFlags.length > 0 ? 'red' : 'green')}`);
  if ((risks.redFlags || []).length > 0) {
    console.log(colorize('\nSecurity Concerns:', 'red'));
    risks.redFlags.forEach(flag => {
      const c = flag.severity === 'high' ? 'red' : flag.severity === 'medium' ? 'yellow' : 'gray';
      const loc = flag.function !== 'global' ? ` in ${colorize(flag.function + '()', 'cyan')}` : '';
      const text = String(flag.text || '').trim();
      console.log(`  [${colorize(flag.severity.toUpperCase(), c)}] Line ${colorize(String(flag.line), 'blue')}${loc}:`);
      console.log(`    ${colorize(text.slice(0, 80) + (text.length > 80 ? '...' : ''), 'gray')}`);
    });
  }

  const checksumTypes = Object.keys(obj.checksums || {});
  if (checksumTypes.length > 0) console.log(colorize('\nChecksums:', 'bold') + ` ${colorize(checksumTypes.join(', '), 'green')}`);
  console.log('');
}

export function printSummary(obj) {
  const { meta, risks, sources, functions } = obj;
  const funcCount = Object.keys(functions || {}).length;
  console.log(`PKGBUILD: ${meta.pkgname || '(unknown)'} ${meta.pkgver || '(unknown)'} — sources:${sources.length} git-unpinned:${risks.unpinnedGitCount} non-https:${risks.nonHttpsCount} redflags:${risks.redFlags.length} severity:${risks.severity} functions:${funcCount}`);
}

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

export function printRedflagsLines(obj) {
  for (const rf of (obj.risks.redFlags || [])) {
    const text = String(rf.text || '').replace(/\t/g, '  ');
    console.log(`${rf.line}\t${text}`);
  }
}

export function printSourcesCompact(obj, limit = 0) {
  const items = obj.sources.map((s, i) => `[${i}] ${s.name} -> ${s.domain} ${s.isGit ? '(git)' : ''}${s.pin ? ` pin:${s.pin.kind}=${String(s.pin.value).slice(0,8)}` : ''}`);
  const out = limit > 0 ? items.slice(0, limit) : items;
  out.forEach(l => console.log(l));
}

