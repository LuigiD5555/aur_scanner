// SPDX-License-Identifier: MIT
// Copyright (c) 2025 José Luis López López Prieto <ing.jlllopezp@gmail.com>
// Author GitHub: https://github.com/LuigiD5555
// composePkgbuildParser.js — PKGBUILD parser composition (spider + processors)
import { processArray } from './extractPkgbuildArraysAndMapFields.js';
import { processScalarAssignment } from './extractScalarsToMetaAndChecksums.js';
import { processSources } from './analyzeSourcesResolvePinsAndDomains.js';
import { calculateSeverity, calculateRiskSeverity } from './computeRiskScoresAndSeverity.js';
import { createInitialResult } from './core/state.js';
import { crawlPKGBUILD } from './spider/crawlPkgbuildAndEmitHooks.js';
import { createRequire } from 'node:module';

// Simple LRU cache for parsed PKGBUILD results by content hash
const CACHE_CAPACITY = 32;
const parseCache = new Map(); // key: sha1(text), value: parsed object
const requireNode = createRequire(import.meta.url);

export function parsePKGBUILD(text) {
  // Hash (best-effort); if hashing fails, skip caching.
  let key = null;
  try {
    const crypto = requireNode('node:crypto');
    key = crypto.createHash('sha1').update(text).digest('hex');
    if (parseCache.has(key)) {
      const cached = parseCache.get(key);
      return typeof structuredClone === 'function' ? structuredClone(cached) : JSON.parse(JSON.stringify(cached));
    }
  } catch (_) { /* ignore caching if crypto not available */ }

  const result = createInitialResult();

  crawlPKGBUILD(text, {
    functionStart(name) { result.functions[name] = true; },
    array(key, content) { processArray(key, content, result); },
    scalar(key, value) { processScalarAssignment(key, value, result); },
    redflag(i, strippedLine, originalLine, currentFunction) {
      result.risks.redFlags.push({
        line: i + 1,
        text: originalLine.trim(),
        function: currentFunction || 'global',
        severity: calculateSeverity(strippedLine)
      });
    }
  });

  processSources(result);
  calculateRiskSeverity(result);

  if (key) {
    if (parseCache.has(key)) parseCache.delete(key);
    parseCache.set(key, result);
    if (parseCache.size > CACHE_CAPACITY) {
      const firstKey = parseCache.keys().next().value;
      parseCache.delete(firstKey);
    }
  }
  return result;
}

export { processArray } from './extractPkgbuildArraysAndMapFields.js';
export { processScalarAssignment } from './extractScalarsToMetaAndChecksums.js';
export { processSources, analyzeSource, calculateSourceRisk } from './analyzeSourcesResolvePinsAndDomains.js';
export { calculateSeverity, calculateRiskSeverity } from './computeRiskScoresAndSeverity.js';
