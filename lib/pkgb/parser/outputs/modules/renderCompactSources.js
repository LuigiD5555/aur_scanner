// renderCompactSources.js — outputs compact sources list

export function printSourcesCompact(obj, limit = 0) {
  const items = obj.sources.map((s, i) => `[${i}] ${s.name} -> ${s.domain} ${s.isGit ? '(git)' : ''}${s.pin ? ` pin:${s.pin.kind}=${s.pin.value.slice(0,8)}` : ''}`);
  const out = limit > 0 ? items.slice(0, limit) : items;
  out.forEach(l => console.log(l));
}

