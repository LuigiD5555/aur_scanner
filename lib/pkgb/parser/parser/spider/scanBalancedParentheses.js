// SPDX-License-Identifier: MIT
// Copyright (c) 2025 José Luis López López Prieto <ing.jlllopezp@gmail.com>
// Author GitHub: https://github.com/LuigiD5555
// scanBalancedParentheses.js — scans a line updating balanced parentheses outside quotes/escapes

export function scanBalancedParentheses(line, state) {
  let { inSingle, inDouble, esc, depth } = state;
  for (const ch of line) {
    if (esc) { esc = false; continue; }
    if (ch === '\\') { esc = true; continue; }
    if (!inSingle && ch === '"') { inDouble = !inDouble; continue; }
    if (!inDouble && ch === "'") { inSingle = !inSingle; continue; }
    if (!inSingle && !inDouble) {
      if (ch === '(') depth++;
      else if (ch === ')') depth--;
    }
  }
  return { inSingle, inDouble, esc, depth };
}
