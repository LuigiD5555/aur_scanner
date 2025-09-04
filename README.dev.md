# Developer Notes (Internal)

This document captures implementation details, tuning knobs, and maintenance notes that are intentionally not surfaced in the main README. It is meant for contributors and maintainers.

## Architecture Overview

- Bash entrypoint: `bin/aur-verify`
- Verify runner: `lib/verify/runner.sh` orchestrates the end-to-end flow and installation handoff
- Atomic rules: `lib/verify/rules.sh` aggregates `lib/verify/rules/*.sh`
  - `vcs_pinning_rule.sh`, `sources_rule.sh`, `checksums_rule.sh`, `verifysource_rule.sh` (and `redflags_rule.sh` available; see note below)
- AUR fetchers and RPC helpers: `lib/aur/fetch_plain_and_snapshot.sh`
- AUR search/resolve utilities: `lib/aur/search_and_resolve.sh`
- GitHub wrapper derivation: `lib/github/derive_candidates_from_repo.sh`
- PKGBUILD helpers: `lib/pkgb/aggregate_pkgb_helpers.sh` aggregates:
  - `sources_and_domains.sh`, `checksums_policy.sh`, `redflags_scan.sh`, `functions_summary.sh`
- Report + i18n: `lib/report/render_summary.sh`, `lib/i18n/messages.sh`
- Optional Node parser: `bin/pkgb-parse` with `lib/pkgb/parser/{analysis,utils,outputs,patterns,terminalColors}.js`

## Verification Depth and Precedence

- `--verify-only`: static checks only (no install). With `DEEP=1` it also runs `makepkg --verifysource`.
- `--fast`: metadata-only; skips deep verification even if `DEEP=1` is set (FAST wins over DEEP).
- `STRICT=1`: tightens policies (HTTPS-only, domain allowlist, strong checksums, VCS pinning) and may elevate WARN to FAIL.

## Logging Modes

- `--verbose` (or `VERBOSE=1`):
  - Implies `SHOW_FUNCS=1`
  - Prints compact sources list from JS parser, summary line, and red flags lines (diagnostics only).
- `--quiet` (or `QUIET=1`):
  - Suppresses info/warn logs globally; summary and errors remain.
  - Overrides `--verbose` and disables `SHOW_FUNCS`/metadata.
- Function summaries can also be shown explicitly with `SHOW_FUNCS=1` regardless of `--verbose`.

## Performance Tweaks (Internal)

- AUR RPC exact-name check is attempted first to avoid slow searches (`aur_plain_rpc_info`).
- `lib/aur/fetch_plain_and_snapshot.sh` implements plain PKGBUILD caching:
  - Env vars: `AUR_CACHE_DIR` (default `/tmp/aur-plain-cache`), `AUR_CACHE_TTL_SEC` (default `3600`).
  - `.SRCINFO` is fetched only in VERBOSE or STRICT.
  - `curl` uses compression, small timeouts and follows redirects.
- Checksum rewrite is skipped when `FAST=1`; otherwise `rewrite_sums_to_sha256` attempts to upgrade to sha256sums.

## Red Flags Handling (current behavior)

- The atomic rule exists: `rule_red_flags()` (Bash) and JS diagnostics are available, but the runner does not currently add a red-flags item to the summary report.
- In `--verbose`, JS red flags lines are printed as diagnostics if the Node parser is available.
- Policy in `redflags_rule.sh` (when invoked) treats the architecture-selection eval pattern as low risk (WARN normal / FAIL strict); other patterns WARN/FAIL accordingly.

## Node Parser Integration (`bin/pkgb-parse`)

- Optional: used opportunistically when Node is present; otherwise safe stubs are loaded.
- Provided outputs used by the Bash CLI:
  - `--summary`, `--sources-compact`, and `--redflags-lines` (diagnostics only)
- ESM modules live under `lib/pkgb/parser`; parsing and formatting concerns are separated.

## Adding/Adjusting Rules

- Prefer small, composable functions in `lib/verify/rules/*.sh` that:
  - Log only snippets (full context in VERBOSE)
  - Update the report via `report_add <item> <STATUS> <message_key>`
  - Return non-zero only when the rule should contribute to failure
- Add user-facing messages in `lib/i18n/messages.sh` (both EN and ES).

## Tests and Local Tips

- Run tests (requires bats):
  - `scripts/run-tests.sh`
  - Or directly: `bats tests`

- Quick loop on a target package:
  - `STRICT=1 sh ./bin/aur-verify <pkg> --verify-only --verbose`
  - `FAST=1 sh ./bin/aur-verify <pkg> --verify-only`
  - `DEEP=1 sh ./bin/aur-verify <pkg> --verify-only`
- Quick pre-check before install (aur-guard):
  - Explicit: `bin/aur-guard yay -S <pkg>` (likewise for paru/pikaur/trizen, `pamac build <pkg>`)
  - Drop-in: symlink `bin/aur-guard` to `~/.local/bin/{yay,paru,pikaur,trizen,pamac}`
- Clear cache to re-fetch a PKGBUILD:
  - `rm -f /tmp/aur-plain-cache/<pkg>.PKGBUILD`

## Release/Docs Notes

- Keep README focused on usage and stable flags. Place internal tuning and rationale here.
- Do not link this file from README unless intentionally surfacing to users.

## DRY and Ownership of Rules

- Red flags list: `lib/rules/redflags.list`
  - Bash: `lib/pkgb/redflags_scan.sh` -> `scan_red_flags()` (`grep -E -f`)
  - JS: `lib/pkgb/parser/patterns/compileRegexPatterns.js` loads the same list
- Enforcement (PASS/WARN/FAIL) is in Bash rules. JS parser is diagnostics-only.

## Bash Layout (modular)

- Core: `lib/core/shell_safety.sh`
- Logging: `lib/utils/logging.sh`
- AUR fetchers: `lib/aur/fetch_plain_and_snapshot.sh`
- AUR search/resolve: `lib/aur/search_and_resolve.sh`
- GitHub candidates: `lib/github/derive_candidates_from_repo.sh`
  - Repo metadata (optional): pulled via `$YAY_BIN -Si` when helper is present
- PKGBUILD helpers: `lib/pkgb/{sources_and_domains,checksums_policy,redflags_scan,functions_summary}.sh` (aggregated by `aggregate_pkgb_helpers.sh`)
- Verify rules: `lib/verify/rules/*.sh` (aggregated by `lib/verify/rules.sh`)
- Verify runner: `lib/verify/runner.sh`
- i18n: `lib/i18n/messages.sh`
- Report: `lib/report/render_summary.sh`

### Import sanity check after refactors

Run `bash scripts/validate-sources.sh` to validate all `source "..."` references point to existing files.
Optionally, add a `.git/hooks/pre-commit` hook to invoke that script.

The script resolves `$SCRIPT_DIR`/`$LIB_DIR` heuristically and validates module existence. Handy after renames/moves.

## Function Reference (concise)

<details>
<summary><strong>Verifier runner and rules</strong></summary>

- `verify_pkgbuild(pkg)`: Orchestrates checkout, rules, reporting, and optional install.
- `install_or_verify(pkg)`: Shows metadata in verify-only (when enabled) and calls `verify_pkgbuild`.
- `aur_checkout_to(pkg, workdir)`: Fetches PKGBUILD via AUR plain → snapshot → git fallback.

- `rule_vcs_pinning(pkgb, strict)`: Enforce pinning for `git+` sources (`#commit=`/`#tag=`).
- `rule_sources(pkgb, strict)`: Enforce HTTPS-only and allowed domains.
- `rule_checksums(pkgb, checkout, strict, fast)`: Enforce strong sums; auto-rewrite to sha256 unless strict/fast.
- `rule_verifysource(checkout, mode, strict)`: Run `makepkg --verifysource` depending on mode; WARN vs FAIL in strict.
- `rule_red_flags(pkgb, strict)`: Available rule; not currently included in the default runner summary.

</details>

<details>
<summary><strong>PKGBUILD helpers</strong></summary>

- `list_sources()`: Extract sources array (normalized, stripped).
- `sources_have_only_https()`: Test stream for HTTPS-only.
- `sources_domains_allowed()`: Test stream against allowlist.
- `has_strong_sums()`, `has_weak_or_skip()`: Detect checksum policy.
- `rewrite_sums_to_sha256(dir)`: Use `makepkg -g` and rewrite checksum arrays.
- `scan_red_flags(pkgb)`: Grep against `lib/rules/redflags.list` with line numbers.
- `print_func_summaries(pkgb)`: Extract prepare/build/package snippet bodies.
- `pkgb_check_vcs_pinning(pkgb)`: Check for unpinned VCS sources.

</details>

<details>
<summary><strong>AUR/GitHub and resolver</strong></summary>

- `aur_plain_fetch_plain_files`, `aur_plain_fetch_repo`: Fetch PKGBUILD/.SRCINFO or snapshot tarball.
- `aur_plain_rpc_info|search|exists`: RPC helpers and discovery.
- `resolve_pkg(input)`: Resolve an input token or GitHub URL to an AUR package name.
- `aur_search_name_strict_aur_only`, `prefer_fast_variant`: Name-strict search and fast-variant biasing.
- `is_github_url`, `build_candidates_from_github`, `github_default_branch`: Wrapper candidate derivation.

</details>
