# Developer Notes (Internal)

This document captures implementation details, tuning knobs, and maintenance notes that are intentionally not surfaced in the main README. It is meant for contributors and maintainers.

## Architecture Overview

- Bash entrypoint: `bin/aur-verify`
- Core verification: `lib/verify.sh` + atomic rules in `lib/verify_rules.sh`
- AUR fetchers: `lib/aur_plain.sh` (plain/snapshot; git fallback in `verify.sh`)
- PKGBUILD helpers: `lib/pkgb.sh`
- Report + i18n: `lib/report.sh`, `lib/i18n.sh`
- Optional Node parser: `bin/pkgb-parse` with `lib/js_node/{analysis,utils,outputs,patterns,colors}.js`

## Verification Depth and Precedence

- `--verify-only`: static checks only (no install). With `DEEP=1` it also runs `makepkg --verifysource`.
- `--fast`: metadata-only; skips deep verification even if `DEEP=1` is set (FAST wins over DEEP).
- `STRICT=1`: tightens policies (HTTPS-only, domain allowlist, strong checksums, VCS pinning) and may elevate WARN to FAIL.

## Logging Modes

- `--verbose` (or `VERBOSE=1`):
  - Implies `SHOW_FUNCS=1`
  - Prints compact sources list, JS parser summaries, and shows full context for incidents.
- `--quiet` (or `QUIET=1`):
  - Suppresses info/warn logs globally; summary and errors remain.
  - Overrides `--verbose` and disables `SHOW_FUNCS`.
- Function summaries can also be shown explicitly with `SHOW_FUNCS=1` regardless of `--verbose`.

## Performance Tweaks (Internal)

- AUR RPC name resolution uses a single RPC call for bare names to avoid duplicates.
- `lib/aur_plain.sh` implements a simple PKGBUILD cache for AUR plain endpoint:
  - Env vars:
    - `AUR_CACHE_DIR` (default: `/tmp/aur-plain-cache`)
    - `AUR_CACHE_TTL_SEC` (default: `3600`)
  - `.SRCINFO` is fetched only in VERBOSE or STRICT.
  - `curl` uses `--compressed`, timeouts and redirect following.
- Checksum rewrite is skipped in `VERIFY_ONLY=1` (reported as WARN) to avoid network and `makepkg -g` work. In non-verify-only, it attempts `sha256` auto-upgrade unless `--fast` is active.

## Red Flags Handling

- Centralized in `rule_red_flags()` with JS parser preferred (fallback: grep heuristics).
- Special-case (benign) pattern: eval indirection to select a file by CPU architecture, e.g.
  - `$(eval echo "\${_anki_whl_$CARCH}")`
  - Policy: WARN in normal mode; FAIL in `STRICT=1`.
  - Summary message key: `redflags_warn_arch_eval`.
- Other matches follow standard policy: WARN (normal) / FAIL (strict), with snippets-only by default and expanded context in VERBOSE.

## Node Parser Integration (bin/pkgb-parse)

- The CLI is modular and used opportunistically when Node is present:
  - `lib/js.sh` discovers `node` and calls `bin/pkgb-parse` with `--signals` or other flags.
  - Provided outputs:
    - `--signals`: key=value (sources, unpinnedGit, nonHttps, redFlags, severity, functions)
    - `--redflags-lines`: `line<TAB>content`
    - `--sources-compact [--limit N]`
- ESM modules placed in `lib/js_node` keep parsing/formatting concerns separated.

## Adding/Adjusting Rules

- Prefer small, composable functions in `lib/verify_rules.sh` that:
  - Log only snippets for incidents (full context in VERBOSE)
  - Update the report via `report_add <item> <STATUS> <message_key>`
  - Return non-zero only when the rule should contribute to failure
- Add user-facing messages in `lib/i18n.sh` (both EN and ES).

## Tests and Local Tips

- Run tests (requires bats):
  - `scripts/run-tests.sh`
  - Or directly: `bats tests`

- Quick loop on a target package:
  - `STRICT=1 sh ./aur_verify_then_yay.sh <pkg> --verify-only --verbose`
  - `FAST=1 sh ./aur_verify_then_yay.sh <pkg> --verify-only`
  - `DEEP=1 sh ./aur_verify_then_yay.sh <pkg> --verify-only`
- Clear cache to re-fetch a PKGBUILD:
  - `rm -f /tmp/aur-plain-cache/<pkg>.PKGBUILD`

## Release/Docs Notes

- Keep README focused on usage and stable flags. Place internal tuning and rationale here.
- Do not link this file from README unless intentionally surfacing to users.

## DRY and Ownership of Rules

- Red flags list lives in `lib/rules/redflags.list` and is consumed by:
  - Bash: `lib/pkgb.sh` -> `scan_red_flags()` via `grep -E -f`
  - JS: `lib/js_node/patterns.js` loads the same file
- Enforcement (PASS/WARN/FAIL) stays in Bash (`lib/verify_rules.sh`).
- JS parser is diagnostics-only (summaries, sources and red flag lines in VERBOSE).
