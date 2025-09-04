// renderRedflagsLines.js — outputs red flags as line<TAB>content

export function printRedflagsLines(obj) {
  for (const rf of (obj.risks.redFlags || [])) {
    const text = String(rf.text || '').replace(/\t/g, '  ');
    console.log(`${rf.line}\t${text}`);
  }
}
/*
  License: CC BY-NC-SA 4.0 (https://creativecommons.org/licenses/by-nc-sa/4.0/)
  Copyright (c) 2025 José Luis López López Prieto
*/
