// renderRedflagsLines.js — outputs red flags as line<TAB>content

export function printRedflagsLines(obj) {
  for (const rf of (obj.risks.redFlags || [])) {
    const text = String(rf.text || '').replace(/\t/g, '  ');
    console.log(`${rf.line}\t${text}`);
  }
}

