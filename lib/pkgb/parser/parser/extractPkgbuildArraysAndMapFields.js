// SPDX-License-Identifier: MIT
// Copyright (c) 2025 José Luis López López Prieto
// Author GitHub: https://github.com/LuigiD5555
// extractPkgbuildArraysAndMapFields.js — extracts PKGBUILD array assignments
// and maps them into result.arrays plus derived fields (dependencies, arch, etc.)
import { splitItems } from '../utils/modules/parseShellStyleTokensAndStripComments.js';

export function processArray(key, content, result) {
  const inner = content.replace(/^[^(]*\(/, '').replace(/\)[^)]*$/, '');
  const items = splitItems(inner);
  result.arrays[key] = items;
  if (key === 'depends') result.dependencies.runtime = items;
  else if (key === 'makedepends') result.dependencies.make = items;
  else if (key === 'checkdepends') result.dependencies.check = items;
  else if (key === 'optdepends') result.dependencies.optional = items;
  else if (key === 'arch') result.architecture = items;
  else if (key === 'conflicts') result.conflicts = items;
  else if (key === 'provides') result.provides = items;
}
