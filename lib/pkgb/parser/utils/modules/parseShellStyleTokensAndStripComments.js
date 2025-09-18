// SPDX-License-Identifier: MIT
// Copyright (c) 2025 José Luis López López Prieto
// Author GitHub: https://github.com/LuigiD5555
// parseShellStyleTokensAndStripComments.js — tokenizes shell-style arrays and strips comments

export function stripComments(line) {
  let out = '';
  let inSingle = false, inDouble = false, esc = false;
  for (const ch of line) {
    if (esc) { out += ch; esc = false; continue; }
    if (ch === '\\') { out += ch; esc = true; continue; }
    if (!inSingle && ch === '"') { out += ch; inDouble = !inDouble; continue; }
    if (!inDouble && ch === "'") { out += ch; inSingle = !inSingle; continue; }
    if (!inSingle && !inDouble && ch === '#') break;
    out += ch;
  }
  return out;
}

export function splitItems(raw) {
  const str = raw.trim();
  const items = [];
  let buf = '';
  let inSingle = false, inDouble = false, esc = false;
  for (const ch of str) {
    if (esc) { buf += ch; esc = false; continue; }
    if (ch === '\\') { buf += ch; esc = true; continue; }
    if (!inSingle && ch === '"') { buf += ch; inDouble = !inDouble; continue; }
    if (!inDouble && ch === "'") { buf += ch; inSingle = !inSingle; continue; }
    if (!inSingle && !inDouble && /[\s]+/.test(ch)) {
      if (buf.trim()) items.push(unquote(buf.trim()));
      buf = '';
      continue;
    }
    buf += ch;
  }
  if (buf.trim()) items.push(unquote(buf.trim()));
  return items;
}

function unquote(raw) {
  const quoted = raw.match(/^['"](.*)['"]$/);
  return quoted ? quoted[1].replace(/\\([\\"'])/g, '$1') : raw;
}

