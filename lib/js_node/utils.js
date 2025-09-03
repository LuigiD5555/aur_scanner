// utils.js — helpers for parsing, IO, and fetching
import https from 'https';
import http from 'http';

export function stripComments(line) {
  let result = '';
  let inSingle = false, inDouble = false, escaped = false;
  for (let i = 0; i < line.length; i++) {
    const char = line[i];
    if (escaped) { result += char; escaped = false; continue; }
    if (char === '\\') { result += char; escaped = true; continue; }
    if (!inSingle && char === '"') { inDouble = !inDouble; result += char; continue; }
    if (!inDouble && char === "'") { inSingle = !inSingle; result += char; continue; }
    if (!inSingle && !inDouble && char === '#') { break; }
    result += char;
  }
  return result;
}

export function splitItems(input) {
  const items = [];
  const regex = /"([^"\\]*(?:\\.[^"\\]*)*)"|'([^'\\]*(?:\\.[^'\\]*)*)'|[^\s]+/g;
  let match;
  while ((match = regex.exec(input)) !== null) {
    let value = match[1] ?? match[2] ?? match[0];
    if (match[1] || match[2]) {
      value = value.replace(/\\([\\"'])/g, '$1');
    }
    items.push(value);
  }
  return items;
}

export function fetchFromURL(url) {
  return new Promise((resolve, reject) => {
    const client = url.startsWith('https:') ? https : http;
    const options = { headers: { 'User-Agent': 'pkgb-parse/2.0 (AUR PKGBUILD parser)' }, timeout: 15000 };
    const req = client.get(url, options, (res) => {
      if (res.statusCode >= 300 && res.statusCode < 400 && res.headers.location) {
        const next = res.headers.location.startsWith('http') ? res.headers.location : new URL(res.headers.location, url).toString();
        return fetchFromURL(next).then(resolve).catch(reject);
      }
      if (res.statusCode !== 200) { reject(new Error(`HTTP ${res.statusCode}: ${res.statusMessage}`)); return; }
      let data = ''; res.setEncoding('utf8');
      res.on('data', (c) => data += c);
      res.on('end', () => resolve(data));
      res.on('error', reject);
    });
    req.on('error', reject);
    req.on('timeout', () => { req.destroy(); reject(new Error('Request timeout')); });
  });
}

export function readStdin() {
  return new Promise((resolve, reject) => {
    let data = '';
    process.stdin.setEncoding('utf8');
    process.stdin.on('data', chunk => data += chunk);
    process.stdin.on('end', () => resolve(data));
    process.stdin.on('error', reject);
  });
}

