// SPDX-License-Identifier: MIT
// Copyright (c) 2025 José Luis López López Prieto
// Author GitHub: https://github.com/LuigiD5555
// terminalColors.js — ANSI color helpers for terminal output
export const colors = {
  reset: '\x1b[0m',
  bold: '\x1b[1m',
  dim: '\x1b[2m',
  red: '\x1b[31m',
  green: '\x1b[32m',
  yellow: '\x1b[33m',
  blue: '\x1b[34m',
  magenta: '\x1b[35m',
  cyan: '\x1b[36m',
  white: '\x1b[37m',
  gray: '\x1b[90m'
};

export function colorize(text, color) {
  if (process.env.NO_COLOR || !process.stdout.isTTY) {
    return text;
  }
  const code = colors[color];
  if (!code) return text;
  return `${code}${text}${colors.reset}`;
}

