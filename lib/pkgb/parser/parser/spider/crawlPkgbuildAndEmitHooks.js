// crawlPkgbuildAndEmitHooks.js — PKGBUILD spider/scraper that crawls lines and emits visitor hooks
import { PATTERNS } from '../../patterns/compileRegexPatterns.js';
import { stripComments } from '../../utils/modules/parseShellStyleTokensAndStripComments.js';
import { scanBalancedCurlyBraces } from './scanBalancedCurlyBraces.js';
import { scanBalancedParentheses } from './scanBalancedParentheses.js';

export function crawlPKGBUILD(text, visitor = {}) {
  const lines = text.replace(/\r/g, '').split(/\n/);

  // Array collection state (balanced parentheses, quotes, escapes)
  let collecting = null; // key of current array
  let buffer = '';
  let arrDepth = 0;
  let arrInSingle = false;
  let arrInDouble = false;
  let arrEsc = false;

  // Function scope tracking (brace depth with quotes/escapes)
  let inFunction = false;
  let currentFunction = null;
  let funDepth = 0; // counts { } once the first { has been seen
  let funSeenOpen = false;
  let funInSingle = false;
  let funInDouble = false;
  let funEsc = false;

  for (const [i, originalLine] of lines.entries()) {
    const line = stripComments(originalLine).trim();
    if (!line) continue;

    // Function start detection
    const funcMatch = line.match(PATTERNS.functionStart);
    if (funcMatch) {
      currentFunction = funcMatch[1];
      inFunction = true;
      funDepth = 0;
      funSeenOpen = false;
      funInSingle = false; funInDouble = false; funEsc = false;
      if (visitor.functionStart) visitor.functionStart(currentFunction, i, line, originalLine);
      // continue scanning this same line to catch inline "{" after declaration
    }

    // Function brace tracking if inside a function
    if (inFunction) {
      const upd = scanBalancedCurlyBraces(originalLine, { inSingle: funInSingle, inDouble: funInDouble, esc: funEsc });
      if (upd.opens > 0) funSeenOpen = true;
      if (funSeenOpen) funDepth += upd.opens - upd.closes;
      funInSingle = upd.inSingle; funInDouble = upd.inDouble; funEsc = upd.esc;
      if (funSeenOpen && funDepth <= 0) {
        if (visitor.functionEnd) visitor.functionEnd(i);
        inFunction = false;
        currentFunction = null;
        funDepth = 0; funSeenOpen = false;
      }
    }

    // Array collection mode
    if (collecting) {
      buffer += ' ' + line;
      const upd = scanBalancedParentheses(line, { inSingle: arrInSingle, inDouble: arrInDouble, esc: arrEsc, depth: arrDepth });
      arrInSingle = upd.inSingle; arrInDouble = upd.inDouble; arrEsc = upd.esc; arrDepth = upd.depth;
      if (arrDepth <= 0) {
        if (visitor.array) visitor.array(collecting, buffer, i);
        collecting = null; buffer = '';
        arrDepth = 0; arrInSingle = false; arrInDouble = false; arrEsc = false;
      }
      continue;
    }

    // Array start detection
    const arrayMatch = line.match(PATTERNS.arrayStart);
    if (arrayMatch) {
      collecting = arrayMatch[1];
      buffer = line;
      const init = scanBalancedParentheses(line, { inSingle: false, inDouble: false, esc: false, depth: 0 });
      arrInSingle = init.inSingle; arrInDouble = init.inDouble; arrEsc = init.esc; arrDepth = init.depth;
      if (arrDepth <= 0) {
        if (visitor.array) visitor.array(collecting, buffer, i);
        collecting = null; buffer = '';
        arrDepth = 0; arrInSingle = false; arrInDouble = false; arrEsc = false;
      }
      continue;
    }

    // Scalar assignment
    const scalarMatch = line.match(PATTERNS.scalarAssign);
    if (scalarMatch && visitor.scalar) visitor.scalar(scalarMatch[1], scalarMatch[2], i);

    // Red flags
    if (PATTERNS.redFlags.test(line) && visitor.redflag) {
      visitor.redflag(i, line, originalLine, currentFunction || 'global');
    }
  }
}
/*
  License: CC BY-NC-SA 4.0 (https://creativecommons.org/licenses/by-nc-sa/4.0/)
  Copyright (c) 2025 José Luis López López Prieto
*/
