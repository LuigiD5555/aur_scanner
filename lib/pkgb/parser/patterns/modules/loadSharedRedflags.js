// loadSharedRedflags.js — loads shared red flags regex (shared with Bash rules)
import { readFileSync } from 'fs';
import path from 'path';
import { fileURLToPath } from 'url';

export function loadSharedRedflags() {
  const __filename = fileURLToPath(import.meta.url);
  const __dirname = path.dirname(__filename);
  // patterns/modules -> up to patterns -> up to parser -> up to pkgb -> up to lib -> into rules
  const rulesPath = path.resolve(__dirname, '../../../../rules/redflags.list');
  try {
    const content = readFileSync(rulesPath, 'utf8');
    const lines = content.split(/\r?\n/)
      .map(l => l.trim())
      .filter(l => l.length > 0 && !l.startsWith('#'));
    return lines.length > 0 ? new RegExp(lines.join('|'), 'i') : new RegExp('(?!)');
  } catch (e) {
    // Enforce single source of truth: if list missing, return a regex that matches nothing
    return new RegExp('(?!)');
  }
}
