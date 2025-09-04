// extractScalarsToMetaAndChecksums.js — extracts scalar assignments and populates
// result.meta for known keys and result.checksums for *sums keys

export function processScalarAssignment(key, value, result) {
  value = value.trim().replace(/^['"]|['"]$/g, '');
  if (['pkgname','pkgver','pkgrel','epoch','pkgdesc','url','license'].includes(key)) {
    result.meta[key] = value;
  }
  if (key.endsWith('sums')) {
    result.checksums[key] = value;
  }
}
/*
  License: CC BY-NC-SA 4.0 (https://creativecommons.org/licenses/by-nc-sa/4.0/)
  Copyright (c) 2025 José Luis López López Prieto
*/
