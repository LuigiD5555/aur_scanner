# AUR Verifier (Bash)

> **Verify first, install later** — Security checker for AUR packages (and GitHub wrappers) with automatic installation via `yay` only if everything passes.

<p align="left">
  <code>Arch</code> · <code>AUR</code> · <code>makepkg --verifysource</code> · <code>PGP</code> · <code>sha256</code> · <code>yay</code>
</p>

---

🌐 Lea esto en [Español](README.es.md)

---

## 🧭 What does this tool do?

This Bash tool takes an AUR package name **or** a GitHub URL and:

1) **Clones** the AUR repository (or **detects** the AUR package wrapping a GitHub URL).  
2) **Audits** the `PKGBUILD` with static checks (common red flags).  
3) **Verifies the integrity** of the sources with `makepkg --verifysource`.  
4) **Fixes** weak checksums (e.g., `sha1sums`/`SKIP`) by replacing them with `sha256sums` (only in normal mode).  
5) **(Optional)** **Strengthens** the policy in **strict mode**: allowed domains, no weak checksums, and PGP verification when `.sig` files exist.  
6) If everything is clean, it **installs** automatically with `yay -S` (unless you use `--verify-only`).

> Designed for those who don’t blindly trust AUR: validate first, install later.

---

## 🚀 Quick start

You can run it either via the legacy wrapper or the new modular entrypoint:

- Wrapper (backward compatible):
  - `sh ./aur_verify_then_yay.sh <package|GitHub_URL>`
- Modular entrypoint:
  - `bash bin/aur-verify <package|GitHub_URL>`

Install after verifying an AUR package:

```bash
sh ./aur_verify_then_yay.sh oreo-nord-cursors-git
```

Verify only (no install):

```bash
sh ./aur_verify_then_yay.sh --verify-only oreo-nord-cursors-git
```

Strict mode (tighter policies):

```bash
STRICT=1 sh ./aur_verify_then_yay.sh oreo-nord-cursors-git
```

Fast verification (metadata only, no `makepkg` downloads):

```bash
FAST=1 sh ./aur_verify_then_yay.sh <AUR-package>
```

Detect and verify from a GitHub repository (finds the AUR wrapper):

```bash
sh ./aur_verify_then_yay.sh https://github.com/OWNER/REPO
```

---

## 📦 Requirements

- Arch Linux or derivative with AUR access.  
- Tools: `git`, `curl`, `makepkg` (part of `pacman`), and an AUR helper: `yay` (default).  
  - You can override the yay binary with `YAY_BIN=/path/to/yay`.

```bash
# Make it executable
chmod +x ./aur_verify_then_yay.sh
```

---

## 🔧 Options and variables

**Flags**:

- `--verify-only` — Run the checks and **exit without installing**.  
- `--fast` — **Metadata-only** verification (skips `makepkg --verifysource`). ⚠️ With `STRICT=1` it reduces guarantees.  
- `-h`/`--help` — Help.

**Environment variables**:

- `STRICT=1` — Enables **strict mode**:
  - **Forbids** `sha1`, `SKIP` or absence of strong checksums.  
  - **Allowlist of domains** (default): `github.com`, `codeload.github.com`, `objects.githubusercontent.com`, `gitlab.com`.  
  - If `.sig` files exist in `source=()`, it **must** pass `makepkg --verifysource` (PGP).  
  - Shows a **summary** of the functions `prepare()`, `build()`, `package()`.  
- `YAY_BIN=/path/to/yay` — Change the yay binary.

---

## ✅ What it checks

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
- With `--fast`, it is deliberately skipped (superficial review using `yay -Si` metadata).

### 6) Summary of `prepare()/build()/package()` (STRICT)

- Displays the **first lines** of each function for quick visibility before installing.

---

## 🧩 How it decides to install

- **Input = AUR package name**  

  Clones `https://aur.archlinux.org/<pkg>.git`, runs checks and, if everything passes, installs with:

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

  If the package is in official repos: installs directly (no build).  

  If it’s AUR and requires compilation, it attempts to **switch** to a fast variant (e.g. `*-bin`). If none exist, it **fails** (to avoid long builds).

---

## 📚 Examples

Verify and install a cursor from AUR (if it exists):

```bash
sh ./aur_verify_then_yay.sh oreo-nord-cursors-git
```

Verify only (no install):

```bash
sh ./aur_verify_then_yay.sh --verify-only oreo-nord-cursors-git
```

Verify an AUR wrapper starting from GitHub:

```bash
sh ./aur_verify_then_yay.sh https://github.com/OWNER/REPO
```

Force strict mode:

```bash
STRICT=1 sh ./aur_verify_then_yay.sh <package>
```

Superficial verification (no `makepkg` downloads):

```bash
FAST=1 sh ./aur_verify_then_yay.sh <package>
```

---

## 🧠 Architecture

### Modular layout

- `bin/aur-verify`: CLI entrypoint that loads modules and orchestrates the flow.
- `lib/common.sh`: shell safety, bash re-exec, tool discovery.
- `lib/log.sh`: structured logging helpers.
- `lib/yay.sh`: metadata extraction from `yay -Si`, repo detection.
- `lib/github.sh`: GitHub URL parsing, README/title scraping, robust repo fallback.
- `lib/search.sh`: candidate generation, strict AUR name search via `yay -Ss` parsing, resolver.
- `lib/pkgb.sh`: PKGBUILD parsers, domain and checksum policies, red-flag scanning.
- `lib/verify.sh`: cloning, verification pipeline, optional installation.
- `aur_verify_then_yay.sh`: legacy wrapper that delegates to `bin/aur-verify`.

Key recent improvements

- Robust GitHub repo parsing with a safe fallback even for edge URLs.
- Name-strict AUR search implemented on top of `yay -Ss` output, filtered to `aur/…` entries.
- Guaranteed non-empty candidate lists to avoid empty search terms.

<details>
<summary><strong>Overview of the flow</strong></summary>

```text
[Input: package or GitHub URL]
        │
        ▼
   Temp dir (mktemp)
        │
        ├─ If GitHub URL → heuristic to find AUR package (owner-repo, -bin, -git...)
        │        │
        │        └─ Verify that PKGBUILD points to that repo
        │
        ├─ Clone AUR: https://aur.archlinux.org/<pkg>.git
        │
        ├─ Static PKGBUILD scan (red flags)
        │
        ├─ Domain validation in source=()
        │
        ├─ makepkg --verifysource
        │        └─ If fails due to weak sums (and STRICT=0): auto-regenerate sha256sums
        │
        ├─ (STRICT) prepare/build/package summary
        │
        ├─ --verify-only ? → exit 0
        │
        └─ Install with yay -S --noconfirm
```

</details>

<details>
<summary><strong>Key modules (high level)</strong></summary>

- **`lib/github.sh`**: URL parsing, README title, kebab-case candidates, safe repo fallback.
- **`lib/search.sh`**: strict `yay -Ss` name search filtered to AUR, candidate ordering, resolver.
- **`lib/pkgb.sh`**: source scanning, checksum policy helpers, function summaries, red flags.
- **`lib/verify.sh`**: clone, makepkg verification, optional checksum rewrite, install path.
- **`lib/yay.sh`**: `yay -Si` field extraction, repo/source metadata.

</details>

<details>
<summary><strong>Technical details (for the curious)</strong></summary>

- **Checksum rewriting**: downloads declared sources, calculates `sha256`, and generates a `sha256sums=()` block in `PKGBUILD` replacing `sha1sums` or `SKIP`.  
- **Function summaries**: prints first lines of `prepare()`, `build()`, `package()` for quick inspection before installing (only with `STRICT=1` and no `--fast`).  
- **Messages**: `[INFO]`, `[WARN]`, `[ERROR]` prefixes for clear logs.  
- **Exit codes**: any failure stops the process with non-zero code.

</details>

---

## 🔐 Security notes

- This script **does not build** the package during verification (uses `makepkg --verifysource`).  
- It does **not** bypass AUR policies: it automates usual controls (and adds stricter rules if you ask).  
- `--fast` is for **superficial review**; use only if you trust the package/maintainer.  
- Domain allowlist and red flags are **opinionated**; you can tweak them in the script if needed.

---

## 🛠️ Troubleshooting

- **“AUR clone failed (package may not exist)”**  

  Check the package name or if it really exists in AUR.
- **“sha256 verification failed after regeneration”**  

  Upstream changed or there may be an attack; don’t install until you understand why.
- **“source domain not allowed” (STRICT)**  

  Add the domain to the allowlist in the script or install in normal mode (at your discretion).
- **“FAST: would require a full AUR build”**  

  Try a `-bin` flavor or run without `--fast` (accepting compilation).

---

## 🧪 Copy‑paste examples

```bash
# Verify and install (normal)
sh ./aur_verify_then_yay.sh <package>

# Verify only
sh ./aur_verify_then_yay.sh --verify-only <package>

# Strict mode (whitelisted domains, no weak sums, PGP when .sig exists)
STRICT=1 sh ./aur_verify_then_yay.sh <package>

# Fast metadata-only verification
FAST=1 sh ./aur_verify_then_yay.sh <package>

# From GitHub: locate AUR wrapper and verify/install
sh ./aur_verify_then_yay.sh https://github.com/OWNER/REPO
```

---

## 📄 License

This project is licensed under the MIT License. See [LICENSE](LICENSE).

---

### Credits

Maintained by the project contributors. See [AUTHORS](AUTHORS) for credits and acknowledgements.
