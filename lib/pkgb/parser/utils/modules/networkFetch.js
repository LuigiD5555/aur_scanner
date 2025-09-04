// networkFetch.js — fetch helper using undici or node:https as fallback
import { createRequire } from 'node:module';
const requireNode = createRequire(import.meta.url);

export async function fetchFromURL(url) {
  try {
    const undici = await import('undici');
    const res = await undici.fetch(url, { redirect: 'follow' });
    if (!res.ok) throw new Error(`HTTP ${res.status}`);
    return await res.text();
  } catch (_) {
    return await new Promise((resolve, reject) => {
      try {
        const { request } = requireNode('node:https');
        const req = request(url, { method: 'GET' }, res => {
          let data = '';
          res.setEncoding('utf8');
          res.on('data', chunk => data += chunk);
          res.on('end', () => resolve(data));
        });
        req.on('error', reject); req.end();
      } catch (e) { reject(e); }
    });
  }
}

