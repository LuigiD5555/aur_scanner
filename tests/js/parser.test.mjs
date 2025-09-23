import test from 'node:test';
import assert from 'node:assert/strict';
import { readFile } from 'node:fs/promises';
import { existsSync } from 'node:fs';
import { fileURLToPath } from 'node:url';
import path from 'node:path';

const __filename = fileURLToPath(import.meta.url);
const __dirname = path.dirname(__filename);
const modulesDir = path.resolve(__dirname, '..', '..', 'lib', 'pkgb', 'parser', 'utils', 'modules');
const hasPkgbModules = existsSync(path.join(modulesDir, 'parseShellStyleTokensAndStripComments.js'));
let parsePKGBUILD;
if (hasPkgbModules) {
  ({ parsePKGBUILD } = await import('../../lib/pkgb/parser/analysis.js'));
}
const pkgbTest = hasPkgbModules ? test : test.skip;

async function loadFixture(relPath) {
  const repoRoot = path.resolve(__dirname, '..', '..');
  const target = path.join(repoRoot, 'tests', relPath);
  return readFile(target, 'utf8');
}

pkgbTest('parsePKGBUILD exposes risk counters for sources', async () => {
  const fixture = await loadFixture('fixtures/js_signals/PKGBUILD');
  const parsed = parsePKGBUILD(fixture);
  assert.equal(parsed?.risks?.unpinnedGitCount, 1, 'should detect one unpinned git source');
  assert.equal(parsed?.risks?.nonHttpsCount, 1, 'should detect one non-HTTPS source');
  const domains = parsed?.sources?.map((s) => s.domain) ?? [];
  assert.ok(domains.includes('example.com'), 'should capture source domains');
});

pkgbTest('parsePKGBUILD handles pinned git sources without raising risks', async () => {
  const fixture = await loadFixture('fixtures/node/source_append/PKGBUILD');
  const parsed = parsePKGBUILD(fixture);
  assert.equal(parsed?.risks?.unpinnedGitCount, 0, 'pinned git source should not raise risk');
  const domains = parsed?.sources?.map((s) => s.domain) ?? [];
  assert.ok(domains.includes('example.com'), 'should capture domain metadata');
});

pkgbTest('parsePKGBUILD returns risk structure even without red flags', async () => {
  const fixture = await loadFixture('fixtures/node/redflags/PKGBUILD');
  const parsed = parsePKGBUILD(fixture);
  assert.ok(parsed?.risks, 'risks object present');
  assert.equal(typeof parsed?.risks?.severity, 'string', 'severity string provided');
});
