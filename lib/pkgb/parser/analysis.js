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

