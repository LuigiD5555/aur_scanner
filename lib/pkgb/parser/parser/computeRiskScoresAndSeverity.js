// SPDX-License-Identifier: MIT
// Copyright (c) 2025 José Luis López López Prieto
// Author GitHub: https://github.com/LuigiD5555
// computeRiskScoresAndSeverity.js — computes source-level risk and overall severity

export function calculateSeverity(line) {
  const high = ['rm -rf','dd if=','curl|sh','wget|sh','eval','sudo','su -c'];
  const med  = ['systemctl','useradd','chmod 4','setcap','mount','pkexec'];
  const low = line.toLowerCase();
  if (high.some(p => low.includes(p))) return 'high';
  if (med.some(p => low.includes(p))) return 'medium';
  return 'low';
}

export function calculateRiskSeverity(result) {
  const { redFlags, unpinnedGitCount, nonHttpsCount } = result.risks;
  const high = redFlags.filter(f => f.severity === 'high').length;
  const med  = redFlags.filter(f => f.severity === 'medium').length;
  if (high > 0 || unpinnedGitCount > 2) result.risks.severity = 'high';
  else if (med > 0 || unpinnedGitCount > 0 || nonHttpsCount > 1) result.risks.severity = 'medium';
  else result.risks.severity = 'low';
}
