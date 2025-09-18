import test from 'node:test';
import assert from 'node:assert/strict';
import { readFile } from 'node:fs/promises';
import { fileURLToPath } from 'node:url';
import path from 'node:path';
import { parsePKGBUILD } from '../../lib/pkgb/parser/analysis.js';

const __filename = fileURLToPath(import.meta.url);
const __dirname = path.dirname(__filename);

async function loadFixture(relPath) {
  const repoRoot = path.resolve(__dirname, '..', '..');
  const target = path.join(repoRoot, 'tests', relPath);
  return readFile(target, 'utf8');
}

test('parsePKGBUILD exposes risk counters for sources', async () => {
  const fixture = await loadFixture('fixtures/js_signals/PKGBUILD');
  const parsed = parsePKGBUILD(fixture);
  assert.equal(parsed?.risks?.unpinnedGitCount, 1, 'should detect one unpinned git source');
  assert.equal(parsed?.risks?.nonHttpsCount, 1, 'should detect one non-HTTPS source');
  const domains = parsed?.sources?.map((s) => s.domain) ?? [];
  assert.ok(domains.includes('example.com'), 'should capture source domains');
});
