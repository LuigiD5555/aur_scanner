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

