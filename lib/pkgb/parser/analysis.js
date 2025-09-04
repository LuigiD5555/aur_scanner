/*
  License: CC BY-NC-SA 4.0 (https://creativecommons.org/licenses/by-nc-sa/4.0/)
  Copyright (c) 2025 José Luis López López Prieto
*/
// analysis.js — backward-compatible re-exports from modular parser
export {
  parsePKGBUILD,
  processArray,
  processScalarAssignment,
  processSources,
  analyzeSource,
  calculateSourceRisk,
  calculateSeverity,
  calculateRiskSeverity
} from './parser/composePkgbuildParser.js';
