// patterns.js — compiled regexes and constants
import { readFileSync } from 'fs';
import path from 'path';
import { fileURLToPath } from 'url';

function loadSharedRedflags() {
  try {
    const __filename = fileURLToPath(import.meta.url);
    const __dirname = path.dirname(__filename);
    const rulesPath = path.resolve(__dirname, '../rules/redflags.list');
    const content = readFileSync(rulesPath, 'utf8');
    const lines = content.split(/\r?\n/)
      .map(l => l.trim())
      .filter(l => l.length > 0 && !l.startsWith('#'));
    if (lines.length > 0) {
      return new RegExp(lines.join('|'), 'i');
    }
  } catch (_) { /* fallback below */ }
  // Fallback inline set (kept in sync with redflags.list)
  return new RegExp([
    'curl\\s*\\|\\s*(sh|bash)',
    'wget\\s*\\|\\s*(sh|bash)',
    '\\beval\\b\\s+',
    'base64\\s*-d.*\\|',
    'openssl\\s+enc',
    '/dev/tcp/',
    'rm\\s*-rf\\s+(/|\\$)',
    '\\buseradd\\b\\s',
    '\\bsystemctl\\b\\s+(enable|start)',
    '\\bsetcap\\b\\s',
    'chmod\\s+[47][0-9]{3}',
    '\\bpython\\b\\s*-c', '::perl\\s*-e', '::ruby\\s*-e', '::node\\s*-e'.replace(/::/g,''),
    '\\$\\(.*curl.*\\)',
    'dd\\s+if=.*of=/',
    '\\bmount\\b\\s+', '\\bumount\\b\\s+',
    '\\bsu\\b\\s+-c', '\\bsudo\\b\\s+', '\\bpkexec\\b\\s+'
  ].join('|'), 'i');
}

export const PATTERNS = {
  arrayStart: /^([a-zA-Z0-9_]+)\s*=\s*\(/,
  scalarAssign: /^([a-zA-Z0-9_]+)\s*=\s*(.*)$/,
  functionStart: /^(prepare|build|check|package(?:_\w+)?)\(\)/,
  redFlags: loadSharedRedflags(),
  urlScheme: /^([a-zA-Z+]+):/,
  gitRepo: /^git(\+https?)?:|\.git(#|\/|$)/,
  gitPin: /#(commit|tag|branch)=([^&#]+)/,
  httpsCheck: /^https:|^git\+https:/
};
