# AUR Scanner (Bash)

> **Verify first, install later** — Security checker for AUR packages (and GitHub wrappers) with automatic installation via `yay` only if everything passes.

[![Bash](https://img.shields.io/badge/Bash-4EAA25?logo=gnu-bash&logoColor=white)](https://www.gnu.org/software/bash/)
[![Arch Linux](https://img.shields.io/badge/Arch_Linux-1793D1?logo=archlinux&logoColor=white)](https://archlinux.org/)
[![AUR](https://img.shields.io/badge/AUR-1793D1?logo=archlinux&logoColor=white)](https://aur.archlinux.org/)
[![makepkg --verifysource](https://img.shields.io/badge/makepkg--verifysource-enabled-blue)](https://wiki.archlinux.org/title/Makepkg)
[![PGP](https://img.shields.io/badge/PGP-verification-informational?logo=gnupg&logoColor=white)](https://gnupg.org/)
[![sha256](https://img.shields.io/badge/checksums-sha256-success)](https://en.wikipedia.org/wiki/SHA-2)
[![yay](https://img.shields.io/badge/helper-yay-0A0A0A)](https://github.com/Jguer/yay)

---

## Project status

This project was created as a **proof of concept** in response to the **September 2025 attacks** targeting **AUR community packages** in Arch Linux.  
Its initial purpose was to **explore auditing and verification tools** that could contribute to the security of users within this ecosystem.  

At present, the project is **no longer actively maintained**. The code is released under an open-source license for educational and research purposes, and remains available for anyone interested in studying it, reusing it, or continuing its development through a fork.  

---

🌐 Lea esto en [Español](./docs/es/README.es.md)

---

## 📚 Documentation

- Developer docs: [English]([docs/developer/README.dev.md](https://github.com/LuigiD5555/aur_scanner/blob/development/docs/developer/README.dev.md) | [Español]([docs/developer/README.dev.es.md](https://github.com/LuigiD5555/aur_scanner/blob/development/docs/developer/README.dev.es.md)

---

## 🧭 What does this tool do?

This tool takes an AUR package name **or** a GitHub URL and:

- Fetches the PKGBUILD from AUR (plain → snapshot → shallow git as last resort).
- Audits static red flags, HTTPS/allowed domains, checksum policy.
- Verifies sources with `makepkg --verifysource` (when applicable).
- **Strict mode** tightens policies (no weak sums, allowed domains only, PGP when `.sig` exists).
- If everything is clean, installs with `yay -S` (unless `--verify-only`).

> Designed for those who don’t blindly trust AUR: validate first, install later.

---

## ✅ What it checks

### 1) Red flags in `PKGBUILD` (static scan)

First tries JS parser signals (`bin/pkgb-parse`); if unavailable, falls back to Bash heuristics using rules in `lib/rules/redflags.list`. It looks for patterns such as:

- **Self-executing downloads**: `curl|wget ... | (sh|bash)`
- **Dynamic execution**: `eval`, `bash -c`, command substitution `$()`
- **Inline decoding/decryption**: `base64 -d`, `openssl enc`
- **Raw sockets in shell**: `/dev/tcp/`
- **Dangerous removals**: `rm -rf /`, `$*`
- **Privilege/permissions misuse**: `chmod 4xxx/7xxx`, `setcap`, `systemctl (enable|start)`, `useradd`
- **One-liners**: `python -c`, `perl -e`, `ruby -e`, `node -e`

**Result:**

- With **JS parser**: if `redFlags>0` → `WARN` (or `FAIL` in `STRICT=1`).
- With **Bash fallback**: same, but only regex heuristics.

---

### 2) Domains and HTTPS in `source=()`

- **HTTPS enforcement**: marks any non-HTTPS source.
- **Domain whitelist** (default, configurable via `ALLOWED_DOMAINS`):
  `github.com | codeload.github.com | objects.githubusercontent.com | gitlab.com`

**Result:**

- Non-HTTPS → `WARN` (or `FAIL` in `STRICT=1`).
- Outside whitelist → `WARN` (or `FAIL` in `STRICT=1`).

---

### 3) VCS pinning for `git+…`

Requires `#commit=` or `#tag=` in `git+…` sources. Otherwise flagged as **unpinned**.

**Result:**

- Missing pin → `WARN` (or `FAIL` in `STRICT=1`).
- Properly pinned → `PASS`.

---

### 4) Checksum policy

- Detects weak checksums (`md5sums`, `sha1sums`) or **`SKIP`**.
- If strong checksums (`sha256sums` / `sha512sums`) are missing, attempts correction.
- In normal mode (not `--fast` / `--verify-only`), tries to **auto-regenerate** `sha256sums` using `makepkg -g`.

**Result:**

- **`STRICT=1`**: any weak/`SKIP`/missing strong checksum → `FAIL` (no autocorrect).
- **Normal**:
  - `--fast` or `--verify-only` → `WARN` (skip regeneration).
  - Full: if rewrite to `sha256sums` succeeds → `PASS`; otherwise `WARN`.

---

### 5) `makepkg --verifysource` (includes PGP if present)

Runs `makepkg --verifysource` **without building** (downloads/PGP/checksums) only in **full mode**.

**Result:**

- **full (default)**:
  - Success → `PASS`.
  - Failure → `WARN` (or `FAIL` in `STRICT=1`).
- **`--fast`** → skipped.
- **`--verify-only`** (without `DEEP=1`) → skipped.

> If the `PKGBUILD` includes `.sig` files, PGP verification happens inside `--verifysource`.
> If not, nothing fails for missing signatures, though other checks may still warn.

---

### 6) Function summaries (`prepare()/build()/package()`)

If `SHOW_FUNCS=1`, prints a **textual summary** of function bodies (does not execute them) for quick visibility before install.

**Result:** Informational only (no PASS/WARN/FAIL).

---

### 7) JS parser signals (if Node + `bin/pkgb-parse`)

Integrates 3 signal counters:

- `unpinnedGit`, `nonHttps`, `redFlags`

They appear in the report as `item_js_unpinned`, `item_js_https`, `item_js_redflags` with **WARN** severity (upgraded to **FAIL** in `STRICT=1`).

---

## 🧩 Other checks / metadata

- **PKGBUILD source origin**: `plain` | `snapshot` | `git`, plus whether **plain** was available (can be `PASS/WARN/FAIL` depending on `STRICT`).
- **Effective mode**: `full`, `fast`, `verify-only` (controls `--verifysource`).
- **Wrapper integration** (`scan`): aborts helper install if verification results in **FAIL**, and when scanning upgrades (`yay -Syu` / `paru -Syu`) it skips failing packages via `--ignore`.
- **Early short-circuit:** static checks run before any source download; if they fail, heavy steps (e.g. `makepkg --verifysource`) are skipped.

---

## 🚀 Quick start

### Install from AUR (beta)

```bash
yay -S aur-scanner-git
```

- Installs the wrapper files under `/usr/lib/aur-scanner`.
- Run `sudo /usr/lib/aur-scanner/scripts/install-scanner.sh --system` (or the `--user` variant) to wire the helper shims after installing.
- Package is tagged as **beta**; breaking changes are still possible.

### Drop-in wrapper (transparent)

After installing, it wraps your AUR helper transparently:

```bash
yay -Syu <aur-package>
paru -S <aur-package>
pamac build <aur-package>
```

- If verification fails during a single install, the helper is blocked.
- During full upgrades (`yay -Syu`, `paru -Syu`, `pikaur -Syu`, etc.) it pre-scans the pending AUR queue; failures are auto-added to `--ignore` so the rest keep updating.
- If everything passes, your helper proceeds normally.
- To bypass once, you can set: `SCAN_BYPASS=1` (not recommended).
- Flags such as `--verify-only`, `--strict`, or `--fast` are understood **only when the helper name points to the wrapper**. `scripts/install-scanner.sh` already drops the necessary shims; for manual setups create one yourself (for example `ln -sf /path/to/repo/bin/scan ~/.local/bin/yay`).
- For parser-only checks without downloads, run through the wrapper with `FAST=1 --verify-only` (or `FAST=1 VERIFY_ONLY=1`).
- Helper shims auto-detect wrapper flags: if you type `yay … --verify-only` the shim hands control to `scan`; otherwise it delegates straight to the real helper.
- Unsure which mode you’re in? Run `command -v yay` and `readlink -f "$(command -v yay)"`. If both point to the wrapper path (`…/scan`), you can write `yay -Syu pkg --verify-only`; otherwise call it explicitly as `scan yay -Syu --verify-only pkg` (or create the shim).

> **Note:** pacman doesn’t install AUR packages; it’s left untouched.
>
> All low-level setup is handled by the app. Advanced integration details live in the developer docs.

### ⌨️ Direct CLI (optional for heavy users)

You can also call the verifier directly for finer control:

```bash
aur-scanner <package>
aur-scanner --verify-only <package>
aur-scanner --strict <package>
aur-scanner --fast <package>
aur-scanner https://github.com/OWNER/REPO
```

---

## 🔧 Main options

Every option can be used **either as a flag** or as an **environment variable**:

| Mode              | Flag form           | Env var form     |
| ----------------- | ------------------- | ---------------- |
| Verify only       | `--verify-only`     | `VERIFY_ONLY=1`  |
| Fast check        | `--fast`            | `FAST=1`         |
| Strict policies   | `--strict`          | `STRICT=1`       |
| Verbose logging   | `--verbose`         | `VERBOSE=1`      |
| Quiet logging     | `--quiet`           | `QUIET=1`        |

> Example: both `aur-scanner --strict pkg` and `STRICT=1 aur-scanner pkg` do the same.

---

## 🧩 Usage scenarios

This tool adapts to different needs. Here are practical cases to guide you:

### ✅ Normal mode (default)

```bash
aur-scanner <aur-package>
```

- Use for everyday installs of **well-known AUR packages**.
- Balance between safety and speed.
- Auto-fixes weak checksums, warns but doesn’t block minor issues.

### 🛡️ Strict mode

```bash
aur-scanner --strict <aur-package>
```

- For **security-sensitive setups** or **unknown packages**.
- Only HTTPS from allowed domains.
- No weak/skip checksums.
- Requires valid `.sig` files.

### ⚡ Fast mode

```bash
aur-scanner --fast <aur-package>
```

- For **quick previews** without downloads.
- Useful on low bandwidth or when triaging packages.
- Superficial — use cautiously.

### 🔍 Verify-only

```bash
aur-scanner --verify-only <aur-package>
```

- For **auditing packages without installing**.
- Great for CI/CD pipelines.
- Add `DEEP=1` for full source + PGP checks.

### Usage summary

|  Mode       | Security | Speed     |                        Downloads                             |               Use case                |
| ----------- | -------- | --------- | ------------------------------------------------------------ | ------------------------------------- |
| Normal      | Medium   | Fast      | Yes                                                          | Daily installs of common AUR packages |
| Strict      | High     | Slower    | Yes                                                          | Unknown packages / sensitive systems  |
| Fast        | Low      | Very fast | No                                                           | Quick triage, metadata preview        |
| Verify-only | High     | Variable  | No (default) / Yes (with DEEP=1) without installing anything | Audit only, CI/CD pipelines           |

### 🔀 Example workflows

- **Obscure package:** `STRICT=1 aur-scanner my-unknown-pkg`
- **Daily upgrade (yay wrapper):** `yay -Syu` (auto-ignores AUR updates that fail verification)
- **Quick preview while browsing AUR:** `aur-scanner --fast --verify-only <package-name>`
- **Pipeline audit:** `DEEP=1 aur-scanner --verify-only custom-helper-git`

---

## 🧠 Script Anatomy (current state)

<details>
<summary><strong>High-level flow (bin/aur-verify)</strong></summary>
```
[Input: AUR package name | AUR URL | GitHub URL]
        │
        ├─ Parse flags/env:
        │     --verify-only, --fast, --strict, --verbose, --quiet, --metadata
        │
        ▼
   Resolve AUR package
        │
        ├─ If GitHub URL → derive_candidates_from_repo (README/title → kebab-case)
        │        │
        │        └─ AUR RPC (cache / live) + strict search (fallback: yay -Ss)
        │
        └─ If AUR URL → take final slug; if plain token → normalize & try variants
                  (-git, -bin, -appimage; FAST prefers “non -bin” first)
        │
        ▼
   PKGBUILD checkout
        │
        ├─ Attempt 1: AUR plain (direct PKGBUILD; caches .json from RPC)
        │
        ├─ If that fails and not --fast:
        │        ├─ Attempt 2: snapshot .tar.gz
        │        └─ Attempt 3: git clone (fallback)
        │
        └─ (Verbose/Strict) may also fetch .SRCINFO
        │
        ▼
   Report: PKGBUILD source
        ├─ plain | snapshot | git + “plain available/unavailable”
        └─ (Verbose) summary of prepare()/build()/package()
        │
        ▼
   JS signals (if Node + bin/pkgb-parse available)
        ├─ unpinnedGit / nonHttps / redFlags → export counters
        └─ (Verbose) shows: summary, compact sources, flagged lines
        │
        ▼
   Verification rules (Bash + JS signals)
        ├─ VCS pinning (git+… requires #commit= or #tag=) → PASS/WARN/FAIL (STRICT)
        ├─ HTTPS-only + domain whitelist (ALLOWED_DOMAINS defaults: GitHub/GitLab/…)
        ├─ Checksums:
        │     • If md5/sha1 or SKIP:
        │         - STRICT: FAIL
        │         - --fast: WARN
        │         - --verify-only: WARN
        │         - Normal: auto-regenerate sha256sums (makepkg -g) → PASS/WARN
        ├─ Red flags (via JS if available; fallback grep heuristics)
        └─ makepkg --verifysource (mode depends):
              • full (default) → run
              • fast / verify-only → SKIP
              • STRICT upgrades certain WARN to FAIL
        │
        ▼
   Summary (i18n en/es): PASS/WARN/FAIL + “OK | OK (with warnings) | FAIL”
        │
        ├─ --verify-only → exit with code according to result
        └─ (Installation is NOT automatic here)
```
</details> 

> **VCS:** Version Control System
> **RPC:** Remote Procedure Call

<details>
<summary><strong>Integration with wrapper (bin/scan)</strong></summary>

```plaintext
[Invocation: scan <helper> <args>]
        │
        ├─ Detects real helper (yay/paru/pikaur/trizen/pamac)
        ├─ Extracts candidate packages (pacman -S/-U style or pamac build/install/upgrade)
        ├─ Runs: bin/aur-verify --verify-only -- <candidates>
        │       └─ If verification FAILS → aborts (exit 2)
        │
        └─ If verification OK (or no AUR candidates) → delegates to real helper (exec)
```
</details>

### Quick notes (current behavior)

- **Fetching**: always prefers **AUR plain**; if that fails and not in `--fast`, falls back to **snapshot** and then **git clone**.
- **Resolution**: relies on **AUR RPC v5** with lightweight `/tmp` cache, strict name matching, and as a last resort `yay -Ss`. For GitHub, derives candidates from README/title and normalizes with *kebab-case* + variants (`-git/-bin/-appimage`).
- **Optional JS signals**: if Node and `bin/pkgb-parse` exist, adds signals (unpinnedGit/nonHttps/redFlags) and shows details in `--verbose`.
- **Checksums**: if **md5/sha1/SKIP** are found, normal mode attempts to **auto-replace** with `sha256sums` (unless `--verify-only` or `--fast`); `--strict` treats them as **FAIL**.
- **HTTPS + domains**: requires HTTPS and validates against `ALLOWED_DOMAINS` (env configurable).
- **VCS pinning**: requires `#commit=` or `#tag=` in `git+…` sources (WARN/FAIL depending on `--strict`).
- **makepkg --verifysource**: runs only in **full mode**; skipped in `--fast` or `--verify-only`.
- **Reporting**: internationalized (en/es) with “BEGIN/END” banners, PASS/WARN/FAIL totals, and suggested action.

--

## 🧪 What it checks (summary)

- **VCS pinning**: `git+https://…` should use `#commit=` or `#tag=` (strict = required).
- **Source URLs**: enforce HTTPS and validate against an allowlist (strict).
- **Checksums**: prefer `sha256sums`; weak/ `SKIP` are rejected or auto-rewritten (non-strict).
- **PGP**: if `.sig` is declared, `makepkg --verifysource` must pass.
- **Red flags**: highlights risky patterns (diagnostic).

> See the full rule set and severity table in the [developer docs](docs/developer/README.dev.md).

---

## 🛡️ Security notes

- The verifier **does not build** packages; deep checks rely on `makepkg --verifysource`.
- `--fast` is **superficial**; prefer strict+deep checks for sensitive systems.
- Allowlist and red-flag rules can be customized.

---

## ❓ Troubleshooting

- **“Package may not exist”** → confirm name on AUR.
- **“sha256 verification failed”** → upstream changed; do not install until you understand why.
- **“Plain PKGBUILD unavailable while FAST=1”** → rerun without `--fast`.

More scenarios and logs: see the developer docs.

---

## 🤝 Contributing

Contributions are welcome—code, docs, tests, and rule proposals.

- **Good first issues:** documentation tweaks, clearer error messages, extra tests.
- Please follow the existing coding style and conventions.
- Make sure new features or rules include corresponding tests.
- If you plan a major change, open an issue first to discuss it.

See the developer docs for architecture, rules, and test harness.

⚠️ **Note:** This project is not under active maintenance. Contributions are accepted, but review and merge activity may be limited. Forks are encouraged if you want to expand the project further.

## License

This project is licensed under the MIT License. See [LICENSE](./LICENSE) for more details.

### Credits

Maintained by the project contributors. See [AUTHORS](./AUTHORS) for credits and acknowledgements.
