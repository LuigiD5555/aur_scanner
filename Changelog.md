# 📜 Changelog

All notable changes to this project will be documented in this file.  
The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),  
and this project adheres to [Semantic Versioning](https://semver.org/).

---

## [Unreleased]

- Work in progress toward **1.0.0 stable**.

---

## [0.8.0] - 2025-09-26

### Added
- **Behavior Matrix** under Runtime to clarify flag/mode precedence.
- **Domain Allowlist** subsection under Verification Rules → Sources.
- **Threat Model** subsection under Security Model.
- Explicit security notes:
  - checksum auto-rewrite (`makepkg -g`) only in relaxed modes.
  - `makepkg --verifysource` runs as non-privileged user with `umask 077`.
- Warnings for debug toggles (`SCAN_BYPASS`, `SCAN_REAL_YAY`).

### Changed
- **Contributing** section:
  - Emphasis on local development setup.
  - Added three dev setup methods (direct run, install script, `makepkg`).
- **Table of Contents** corrected to proper GitHub anchors.
- Clear separation between end-user installation (AUR package) vs developer setup.
- Wording consistency improvements (Contributing intro, Guidelines).

---

## [0.7.0] - 2025-09-04

### Added
- Support for `tree?plain=1` fallback in PKGBUILD fetch.
- Extended Node parser with `--signals` output.

### Changed
- Improved i18n reporting (Spanish coverage).
- CI recipe updated to run with `STRICT=1 VERIFY_ONLY=1`.
