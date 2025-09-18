# AUR Verifier (Bash)

> **Verify first, install later** — Security checker for AUR packages (and GitHub wrappers) with automatic installation via `yay` only if everything passes.

[![Bash](https://img.shields.io/badge/Bash-4EAA25?logo=gnu-bash&logoColor=white)](https://www.gnu.org/software/bash/)
[![Arch Linux](https://img.shields.io/badge/Arch_Linux-1793D1?logo=archlinux&logoColor=white)](https://archlinux.org/)
[![AUR](https://img.shields.io/badge/AUR-1793D1?logo=archlinux&logoColor=white)](https://aur.archlinux.org/)
[![makepkg --verifysource](https://img.shields.io/badge/makepkg--verifysource-enabled-blue)](https://wiki.archlinux.org/title/Makepkg)
[![PGP](https://img.shields.io/badge/PGP-verification-informational?logo=gnupg&logoColor=white)](https://gnupg.org/)
[![sha256](https://img.shields.io/badge/checksums-sha256-success)](https://en.wikipedia.org/wiki/SHA-2)
[![yay](https://img.shields.io/badge/helper-yay-0A0A0A)](https://github.com/Jguer/yay)

---

🌐 Lea esto en [Español](docs/es/README.es.md)

---

## 📚  Documentation

- Docs index: [Index](docs/INDEX.md)
- Developer docs: [English](https://github.com/LuigiD5555/aur_verifier/blob/development/docs/developer/README.dev.md) | [Español](https://github.com/LuigiD5555/aur_verifier/blob/development/docs/developer/README.dev.es.md)

---

## 🧭 What does this tool do?

This Bash tool takes an AUR package name **or** a GitHub URL and:

1) **Fetches from AUR directly** using the official plain endpoint first. If fetching fails, it retries an alternative endpoint (`tree?plain=1`) and falls back to snapshot or shallow `git clone` only as a last resort.  
2) **Audits** the `PKGBUILD` with static checks and a fast JavaScript parser when Node.js is available (Bash fallbacks otherwise; used automatically).  
3) **Verifies the integrity** of the sources with `makepkg --verifysource`.  
4) **Fixes** weak checksums (e.g., `sha1sums`/`SKIP`) by replacing them with `sha256sums` (only in normal mode; skipped in `--verify-only` and `--fast`).  
5) **(Optional)** **Strengthens** the policy in **strict mode**: allowed domains, no weak checksums, and PGP verification when `.sig` files exist.  
6) If everything is clean, it **installs** automatically with `yay -S` (unless you use `--verify-only`).

> Designed for those who don’t blindly trust AUR: validate first, install later.

---

## 🚀 Quick start

Run it via the modular entrypoint (recommended):

- `sh ./bin/aur-verify <package|GitHub_URL>`
- or `bash bin/aur-verify <package|GitHub_URL>`

Install after verifying an AUR package:

```bash
sh ./bin/aur-verify oreo-nord-cursors-git
```

Verify only (no install):

```bash
sh ./bin/aur-verify --verify-only oreo-nord-cursors-git
```

Strict mode (tighter policies):

```bash
STRICT=1 sh ./bin/aur-verify oreo-nord-cursors-git
```

Fast verification (metadata only, no `makepkg` downloads):

```bash
FAST=1 sh ./bin/aur-verify <AUR-package>
```

Detect and verify from a GitHub repository (finds the AUR wrapper):

```bash
sh ./bin/aur-verify https://github.com/OWNER/REPO
```

Pre-check before installing (aur-guard):

- Explicit invocation (no PATH changes):

```bash
bin/aur-guard yay -S oreo-nord-cursors-git
bin/aur-guard paru -Syu oreo-nord-cursors-git
bin/aur-guard pikaur -S oreo-nord-cursors-git
bin/aur-guard trizen -S oreo-nord-cursors-git
bin/aur-guard pamac build oreo-nord-cursors-git
# pacman does not install AUR; wrapper just delegates
bin/aur-guard pacman -S neovim
```

- Drop-in after creating the symlink to `~/.local/bin/yay`:

```bash
yay -S oreo-nord-cursors-git
paru -Syu oreo-nord-cursors-git
pikaur -S oreo-nord-cursors-git
trizen -S oreo-nord-cursors-git
pamac build oreo-nord-cursors-git
```

### Automatic settings

Run the installer to automatically create the symlinks and ensure the order in the PATH:

```bash
bash scripts/install-aur-guard.sh            # user mode (recommended)
# or
sudo bash scripts/install-aur-guard.sh --system  # system-wide in /usr/local/bin

# Undo symlinks later if needed
bash scripts/uninstall-aur-guard.sh
sudo bash scripts/uninstall-aur-guard.sh --system
```

---

## Intercepting wrapper (aur-guard)

If you want a pre-check before using your usual AUR helpers (yay/paru/pamac), use the universal wrapper and put it at the beginning of your PATH.

Explicit invocation examples:

```bash
bin/aur-guard yay -S <pkg1> <pkg2>
bin/aur-guard paru -Syu <pkg>
bin/aur-guard pamac build <pkg>
```

Drop-in via symlinks (recommended):

```bash
mkdir -p ~/.local/bin
ln -sf "$(pwd)/bin/aur-guard" ~/.local/bin/yay
ln -sf "$(pwd)/bin/aur-guard" ~/.local/bin/paru
ln -sf "$(pwd)/bin/aur-guard" ~/.local/bin/pikaur
ln -sf "$(pwd)/bin/aur-guard" ~/.local/bin/trizen
ln -sf "$(pwd)/bin/aur-guard" ~/.local/bin/pamac
export PATH="$HOME/.local/bin:$PATH"

# Now use your commands as usual
yay -S <aur-package>
paru -S <aur-package>
pamac build <aur-package>
# optional: pacman symlink delegates without AUR verification
 
```

### Automatic setup

Run the installer to create the symlinks automatically and ensure PATH order:

```bash
bash scripts/install-aur-guard.sh            # user mode (recommended)
# or
sudo bash scripts/install-aur-guard.sh --system  # system-wide into /usr/local/bin

# Undo symlinks later if needed
bash scripts/uninstall-aur-guard.sh
sudo bash scripts/uninstall-aur-guard.sh --system
```

Behavior

- Detects target packages and verifies those that exist in AUR via `bin/aur-verify --verify-only` (AUR RPC v5).
- Aborts if any verification fails; otherwise delegates to the real helper with the same arguments.
- Respects knobs like `STRICT=1`, `FAST=1`, `VERBOSE=1`, `QUIET=1` (affecting `bin/aur-verify`).
- To force the real binary path, set `AUR_GUARD_REAL_YAY=/usr/bin/yay` (analogous for PARU/PAMAC).
- To bypass the wrapper temporarily, use `AUR_GUARD_BYPASS=1`.

Helper behavior (transparent)

- The wrapper does not modify helper behavior; it only runs pre-checks and then delegates with the same args.
- For pamac, pre-checks run only on the explicit AUR flow: `pamac build`. Normal `pamac install|upgrade` are left untouched.

Convenience flags (optional)

- You may pass verifier flags with helpers; the wrapper uses them for pre-checks and strips them before delegating:
  - `--strict` (same as `STRICT=1`)
  - `--fast` (same as `FAST=1`)
  - `--verbose` / `--quiet` (same as `VERBOSE=1` / `QUIET=1`)
  - `--metadata` (same as `SHOW_METADATA=1`)
  - `--verify-only` (run pre-checks and do not install via helper)

Developer note: helper list (extendable)

- Extend `lib/guard/helpers.list` to add new helpers or adjust kinds (`pacman` vs `pamac`).

---

## 📦 Requirements

- Arch Linux or derivative with AUR access.  
- Tools: `git`, `curl`, `makepkg` (part of `pacman`), and an AUR helper: `yay` (default).  
  - You can override the yay binary with `YAY_BIN=/path/to/yay`.

```bash
# No installation required; invoke directly with sh or bash
```

---

## 🔧 Options and variables

**Flags**:

- `--verify-only` — Run static checks and exit without installing (no downloads); set `DEEP=1` to include `makepkg --verifysource`.  
- `--deep` — In verify-only, also run `makepkg --verifysource` (downloads sources and verifies checksums/PGP).  
- `--fast` — **Metadata-only** verification (skips `makepkg --verifysource`). ⚠️ With `STRICT=1` it reduces guarantees.  
- `--verbose` — Print full details for advanced users (show function summaries, repository metadata, and expand incident snippets with full context).
- `--quiet` — Minimal logs (only errors and the final verification summary). Overrides `--metadata`.
- `--metadata` — Show repository metadata (`yay -Si`) even in verify-only (hidden by default to keep it fast).
- `-h`/`--help` — Help.

**Environment variables**:

- `STRICT=1` — Enables **strict mode**:
  - **Forbids** `sha1`, `SKIP` or absence of strong checksums.  
  - **Allowlist of domains** (default): `github.com`, `codeload.github.com`, `objects.githubusercontent.com`, `gitlab.com`.  
  - If `.sig` files exist in `source=()`, it **must** pass `makepkg --verifysource` (PGP).  
  - Shows a **summary** of the functions `prepare()`, `build()`, `package()`.  
- `YAY_BIN=/path/to/yay` — Change the yay binary.
- `AUR_FORCE_IPV4=1` — Force IPv4 in all AUR requests (useful when IPv6 routes are flaky/slow).

Reporting and language:

- The final summary report appears in your terminal language (English by default, Spanish when `LANG`/`LC_*` starts with `es`).
- You can force a language with `REPORT_LANG=en` or `REPORT_LANG=es`.
 - `SHOW_FUNCS=1` — Also show `prepare()/build()/package()` summaries; implied by `--verbose`.
 - `SHOW_METADATA=1` — Show repo metadata in verify-only; implied by `--verbose` (or use `--metadata`).
 - `QUIET=1` — Same effect as `--quiet`.

---

## 🧪 Verification modes and depth

Use these knobs to control how deep the verification goes and how much is shown:

- `--verify-only`: Static checks only by default (no downloads, no install).  
  - Add `DEEP=1` to also run `makepkg --verifysource` (downloads sources and verifies checksums/PGP).  
  - Good for CI or when you want integrity checks without installing.
- `--fast`: Metadata-only mode; skips `makepkg --verifysource` and any downloads.  
  - Takes precedence over `DEEP=1` (i.e., `FAST=1` disables deep verification).
- `STRICT=1`: Tightens policies (HTTPS-only, allowed domains, strong checksums, pinning) and upgrades certain WARN into FAIL.  
- `--verbose` / `--quiet`: Increase details (full context, function summaries) or minimize logs (only errors + final summary).

When to use which

- Quick triage (no downloads): `sh ./bin/aur-verify <pkg> --verify-only --fast`
- Integrity without install: `DEEP=1 sh ./bin/aur-verify <pkg> --verify-only`
- Strict gate for security‑sensitive systems: `STRICT=1 DEEP=1 sh ./bin/aur-verify <pkg> --verify-only`
- Detailed auditing: `STRICT=1 sh ./bin/aur-verify <pkg> --verify-only --verbose`
- Minimal noise: `sh ./bin/aur-verify <pkg> --verify-only --quiet`

Notes

- Deep verification (`DEEP=1`) requires network to fetch sources; it is skipped if `--fast` is set.
- In `--verify-only`, checksum auto‑rewrite is not attempted (no `makepkg -g` downloads).
- Installation path still depends on the overall summary; if it’s FAIL and you’re not in verify‑only, installation is aborted.

---

## 🧩 Node CLI: pkgb-parse (optional)

The project ships a modular Node.js CLI to parse PKGBUILD files quickly and feed extra signals into the Bash reports. It is optional: if Node is unavailable, Bash uses grep/awk heuristics.

- Entry point: `bin/pkgb-parse`

Examples:

```bash
# Parse from file
node bin/pkgb-parse --file ./PKGBUILD --summary

# Parse directly from AUR plain URL
node bin/pkgb-parse --url "https://aur.archlinux.org/cgit/aur.git/plain/PKGBUILD?h=zotero"

# JSON for tooling
node bin/pkgb-parse --file ./PKGBUILD --json
```

<details>
<summary><strong>CLI options (details)</strong></summary>

- `--file PATH`: Parse PKGBUILD from a local file
- `--url URL`: Fetch and parse PKGBUILD from URL
- `--summary`: One‑line summary (name, version, counts)
- `--json`: Structured JSON output
- `--signals`: Key=value pairs for Bash integration
- `--redflags-lines`: Red flags as `line<TAB>content`
- `--sources-compact [--limit N]`: Compact sources list, optionally limited

Tip: If you pass an AUR link that is not the plain endpoint, the CLI will suggest the correct `.../plain/PKGBUILD?h=<pkg>` form and prints “Fetching from AUR (respectfully)...”.

</details>

---

## What it checks

### 1) Red flags in `PKGBUILD` (static)

Looks for dangerous or untrustworthy patterns, for example:

- **Self-executing downloads**: `curl|wget ... (sh|bash)`  
- **TCP sockets in shell**: `/dev/tcp`  
- **Dynamic execution**: `eval`, `$(...)`, `` `...` ``, `exec(`  
- **Inline decoding/decryption**: `base64 -d`, `openssl enc -d`  
- **Suspicious privileges/permissions**: `chmod +s`, `setcap`, writing into `/etc`  
- **Path traps**: misuse of `pkgdir` pointing to `/etc`  
- **(STRICT)** one-liners with `python -c`, `perl -e`, `ruby -e`, `node -e`  

> If something is detected, it **fails** with an explanation.

<details>
<summary><strong>Severity and common benign patterns</strong></summary>

- In normal mode, red flags produce a WARN; in `STRICT=1`, they can escalate to FAIL.
- A frequent low‑risk case is using `eval` for architecture‑based variable indirection, e.g.:

  `python -m installer --destdir="$pkgdir" $(eval echo "\${_anki_whl_$CARCH}")`

  This resolves a variable like `_anki_whl_x86_64`. It’s kept as WARN in normal mode; still FAIL in strict mode.

- Deep verification (`DEEP=1`) is not required for this case; it can increase confidence by validating checksums/PGP via `makepkg --verifysource`.

</details>

### 2) Allowed domains for `source=()`

- Accepts (by default): `github.com`, `codeload.github.com`, `objects.githubusercontent.com`, `gitlab.com`.  
- In `STRICT=1`, **rejects** any other domain.

### 3) Checksum policies

- **Normal mode**: if `sha1sums` or `SKIP` are found, the script **downloads sources**, computes `sha256`, and **rewrites** `sha256sums` → re-verifies.  
- **STRICT=1**: **forbids** weak checksums; no autocorrection → **fails**.

### 4) PGP verification (if `.sig` exists)

- If the `PKGBUILD` declares `.sig` files, it **must** pass `makepkg --verifysource`.  
- If **no** `.sig` exists, it warns (not blocked) — in `STRICT=1` the warning is explicit.

### 5) `makepkg --verifysource`

- Runs **without building** (integrity/PGP only).  
- Skipped when using `--verify-only` (static checks) unless you set `DEEP=1`.  
- Skipped with `--fast` (superficial review using `yay -Si` metadata).

### 6) Summary of `prepare()/build()/package()` (STRICT)

- Displays the **first lines** of each function for quick visibility before installing.

### 7) VCS pinning (git+ sources)

- Warns when a `git+https://…` source lacks `#commit=` or `#tag=`. In `STRICT=1`, this causes a failure. This enforces reproducibility for VCS packages.

### 8) Red flags (diagnostics)

- Red flag scanning is available and JS diagnostics print red-flag lines in `--verbose` when Node is present.
- Note: the current runner does not add a red-flags item to the summary; this is diagnostic output only. The atomic `rule_red_flags` exists and can be invoked independently.

### 9) Final summary report (non‑experts)

- Prints a concise, human‑readable summary (PASS/WARN/FAIL/SKIP) with a final “Overall” verdict and the action taken.
- Localized to English/Spanish based on your terminal.

<details>
<summary><strong>Report fields and meanings</strong></summary>

- PKGBUILD Source: where the PKGBUILD came from (AUR snapshot/plain vs git clone fallback)
- VCS pinning: whether `git+…` sources are pinned to `#commit=` or `#tag=`
- Source URLs: checks that all sources use HTTPS
- Allowed domains: validates domains against an allowlist
- Checksums: enforces/remediates checksum policy (sha256)
- Red flags (diagnostic): suspicious patterns (printed in --verbose when JS is available; not part of the summary items)
- makepkg --verifysource: integrity/PGP verification (skipped in verify‑only unless `DEEP=1`)

Status values:

- PASS: everything is fine
- WARN: potentially risky or non‑ideal, but not blocked
- FAIL: blocking issue; installation is aborted
- SKIP: deliberately not run due to mode (verify‑only/fast)

Language control:

- Auto: uses `LANG`/`LC_*` (Spanish when starting with `es`)
- Force: set `REPORT_LANG=es` or `REPORT_LANG=en`

</details>

---

## How it decides to install

- **Input = AUR package name**  

  Fetches `PKGBUILD` from AUR snapshot/plain (no clone), runs checks and, if everything passes, installs with:

  ```bash
  yay -S --noconfirm <pkg>
  ```

- **Input = GitHub URL (`https://github.com/OWNER/REPO`)**  

  Attempts to map to a typical AUR wrapper:
  - `owner-repo`  
  - `owner-repo-bin`  
  - `owner-repo-git`  
  - and detected variants  

  Only accepts if the `PKGBUILD` actually **points to that repo** (check `source`/`url`).

- **`--fast`**  

  Affects verification depth (skips `makepkg --verifysource`) and biases name resolution to prefer `-bin`/`-appimage` candidates when applicable. It does not alter the final install command beyond that.

---

## Input detection (autodetect)

- AUR package URL (`https://aur.archlinux.org/packages/<name>`): extracts `<name>` and fetches from AUR snapshot/plain.
- GitHub URL: derives likely AUR wrapper names (repo title + repo name, plus `-git`/`-bin`/`-appimage`), validates against AUR.
- Bare name: queries the official AUR RPC v5 for an exact hit first; if none, falls back to name‑strict search on `yay -Ss` limited to AUR results.

This approach minimizes trust on local heuristics and uses AUR’s official endpoints wherever possible.

## Examples

Verify and install a cursor from AUR (if it exists):

```bash
sh ./bin/aur-verify oreo-nord-cursors-git
```

Verify only (no install):

```bash
sh ./bin/aur-verify --verify-only oreo-nord-cursors-git
```

Verify an AUR wrapper starting from GitHub:

```bash
sh ./bin/aur-verify https://github.com/OWNER/REPO
```

Force strict mode:

```bash
STRICT=1 sh ./bin/aur-verify <package>
```

Superficial verification (no `makepkg` downloads):

```bash
FAST=1 sh ./bin/aur-verify <package>
```

---

## Architecture

Developer documentation is in `README.dev.md`. See that file for code structure, modules, internals, and diagrams.

---
## Security notes

- This script **does not build** the package during verification (uses `makepkg --verifysource`).  
- It does **not** bypass AUR policies: it automates usual controls (and adds stricter rules if you ask).  
- `--fast` is for **superficial review**; use only if you trust the package/maintainer.  
- Domain allowlist and red flags are **opinionated**; you can tweak them in the script if needed.

---

## Troubleshooting

- **“AUR clone failed (package may not exist)”**  

  Check the package name or if it really exists in AUR.
- **“sha256 verification failed after regeneration”**  

  Upstream changed or there may be an attack; don’t install until you understand why.
- **“source domain not allowed” (STRICT)**  

  Add the domain to the allowlist in the script or install in normal mode (at your discretion).
-- **“Plain PKGBUILD unavailable for '<pkg>' while FAST=1”**  
  
  FAST mode disables snapshot/git fallbacks. Rerun without `--fast` to allow snapshot/git, or try a `-bin`/`-appimage` variant.
\- **“PKGBUILD not found at '<path>/PKGBUILD' (mode=..., pkg=...)”**  
  Run without `--fast` to allow snapshot/git fallback. If it still fails, please open an issue and include the path shown.

---

## Copy‑paste examples

```bash
# Verify and install (normal)
sh ./bin/aur-verify <package>

# Verify only
sh ./bin/aur-verify --verify-only <package>

# Strict mode (whitelisted domains, no weak sums, PGP when .sig exists)
STRICT=1 sh ./bin/aur-verify <package>

# Fast metadata-only verification
FAST=1 sh ./bin/aur-verify <package>

# From GitHub: locate AUR wrapper and verify/install
sh ./bin/aur-verify https://github.com/OWNER/REPO
```

---

## License

This project is licensed under the MIT License. See [LICENSE](./LICENSE) for more details.


### Credits

Maintained by the project contributors. See [AUTHORS](./AUTHORS) for credits and acknowledgements.
