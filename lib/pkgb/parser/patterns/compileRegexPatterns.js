// compileRegexPatterns.js — compiled regexes and constants for PKGBUILD parsing
import { loadSharedRedflags } from './modules/loadSharedRedflags.js';

export const PATTERNS = {
  arrayStart: /^([a-zA-Z0-9_]+)\s*=\s*\(/,
  scalarAssign: /^([a-zA-Z0-9_]+)\s*=\s*(.*)$/,
  functionStart: /^(prepare|build|check|package(?:_\w+)?)\(\)/,
  redFlags: loadSharedRedflags(),
  urlScheme: /^([a-zA-Z+]+):/,
  gitRepo: /^git(\+https?)?:|\.git(#|\/|$)/,
  gitPin: /#(commit|tag|branch)=([^&#]+)/,
  httpsCheck: /^https:|^git\+https:/
};

