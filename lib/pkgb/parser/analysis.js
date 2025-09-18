// SPDX-License-Identifier: MIT
// Copyright (c) 2025 José Luis López López Prieto
// Author GitHub: https://github.com/LuigiD5555
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
