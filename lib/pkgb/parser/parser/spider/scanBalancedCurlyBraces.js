// SPDX-License-Identifier: MIT
// Copyright (c) 2025 José Luis López López Prieto <ing.jlllopezp@gmail.com>
// Author GitHub: https://github.com/LuigiD5555
// scanBalancedCurlyBraces.js — scans a line counting { } outside of quotes/escapes

export function scanBalancedCurlyBraces(line, state) {
  let { inSingle, inDouble, esc } = state;
  let opens = 0;
  let closes = 0;
  for (const ch of line) {
    if (esc) { esc = false; continue; }
    if (ch === '\\') { esc = true; continue; }
    if (!inSingle && ch === '"') { inDouble = !inDouble; continue; }
    if (!inDouble && ch === "'") { inSingle = !inSingle; continue; }
    if (!inSingle && !inDouble) {
      if (ch === '{') opens++;
      else if (ch === '}') closes++;
    }
  }
  return { opens, closes, inSingle, inDouble, esc };
}
