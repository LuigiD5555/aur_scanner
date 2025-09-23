import test from 'node:test';
import assert from 'node:assert/strict';
import { fileURLToPath } from 'node:url';
import { dirname, resolve } from 'node:path';
import { existsSync } from 'node:fs';
import { execFile } from 'node:child_process';
import { once } from 'node:events';

const __filename = fileURLToPath(import.meta.url);
const __dirname = dirname(__filename);
const repoRoot = resolve(__dirname, '..', '..');
const pkgbParseBin = resolve(repoRoot, 'bin', 'pkgb-parse');
const modulesDir = resolve(repoRoot, 'lib', 'pkgb', 'parser', 'utils', 'modules');
const hasPkgbModules = existsSync(resolve(modulesDir, 'networkFetch.js')) &&
  existsSync(resolve(modulesDir, 'parseShellStyleTokensAndStripComments.js'));
const pkgbTest = hasPkgbModules ? test : test.skip;

function runPkgbParse(...args) {
  return new Promise((resolvePromise, rejectPromise) => {
    execFile('node', [pkgbParseBin, ...args], { cwd: repoRoot }, (error, stdout, stderr) => {
      if (error) {
        error.stdout = stdout;
        error.stderr = stderr;
        rejectPromise(error);
        return;
      }
      resolvePromise({ stdout, stderr });
    });
  });
}

pkgbTest('pkgb-parse summary includes package name', async () => {
  const fixture = resolve(repoRoot, 'tests/fixtures/node/source_append/PKGBUILD');
  const { stdout } = await runPkgbParse('--file', fixture, '--summary');
  assert.match(stdout, /append-fixture/);
});

pkgbTest('pkgb-parse signals report counts', async () => {
  const fixture = resolve(repoRoot, 'tests/fixtures/js_signals/PKGBUILD');
  const { stdout } = await runPkgbParse('--file', fixture, '--signals');
  assert.match(stdout, /unpinnedGit=1/);
  assert.match(stdout, /nonHttps=1/);
});

pkgbTest('pkgb-parse fails gracefully on missing file', async () => {
  try {
    await runPkgbParse('--file', '/nonexistent/PKGBUILD', '--summary');
    assert.fail('expected failure');
  } catch (error) {
    assert.equal(error.code, 1);
    assert.match(error.stderr, /Error:/);
  }
});
