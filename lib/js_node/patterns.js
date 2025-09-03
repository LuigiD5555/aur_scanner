// patterns.js — compiled regexes and constants
export const PATTERNS = {
  arrayStart: /^([a-zA-Z0-9_]+)\s*=\s*\(/,
  scalarAssign: /^([a-zA-Z0-9_]+)\s*=\s*(.*)$/,
  functionStart: /^(prepare|build|check|package(?:_\w+)?)\(\)/,
  redFlags: new RegExp([
    'curl\\s*\\|\\s*(sh|bash)',
    'wget\\s*\\|\\s*(sh|bash)',
    'eval\\s+',
    'base64\\s*-d.*\\|',
    'openssl\\s+enc',
    '/dev/tcp/',
    'rm\\s*-rf\\s+(/|\\$)',
    'useradd\\s',
    'systemctl\\s+(enable|start)',
    'setcap\\s',
    'chmod\\s+[47][0-9]{3}',
    'python\\s*-c', 'perl\\s*-e', 'ruby\\s*-e', 'node\\s*-e',
    '\\$\\(.*curl.*\\)',
    'dd\\s+if=.*of=/',
    'mount\\s+', 'umount\\s+',
    'su\\s+-c', 'sudo\\s+', 'pkexec\\s+'
  ].join('|'), 'i'),
  urlScheme: /^([a-zA-Z+]+):/,
  gitRepo: /^git(\+https?)?:|\.git(#|\/|$)/,
  gitPin: /#(commit|tag|branch)=([^&#]+)/,
  httpsCheck: /^https:|^git\+https:/
};

