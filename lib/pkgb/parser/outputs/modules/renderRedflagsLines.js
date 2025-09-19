// SPDX-License-Identifier: MIT
// Copyright (c) 2025 José Luis López López Prieto <ing.jlllopezp@gmail.com>
// Author GitHub: https://github.com/LuigiD5555
// renderRedflagsLines.js — outputs red flags as line<TAB>content

export function printRedflagsLines(obj) {
  for (const rf of (obj.risks.redFlags || [])) {
    const text = String(rf.text || '').replace(/\t/g, '  ');
    console.log(`${rf.line}\t${text}`);
  }
}
/*
  Copyright (c) 2025 José Luis López López Prieto <ing.jlllopezp@gmail.com>
*/
