#!/usr/bin/env python3
"""Prepare release docs for beta/stable branches.

- Remove developer documentation directory.
- Rewrite README links to point to development branch on GitHub.
- Drop install-scanner references from user-facing docs.
"""

from __future__ import annotations

import subprocess
from pathlib import Path
from typing import Iterable

REPO_ROOT = Path(__file__).resolve().parents[1]
TARGET_FILES = [
    REPO_ROOT / "README.md",
    REPO_ROOT / "docs/es/README.es.md",
]
INDEX_FILE = REPO_ROOT / "docs/INDEX.md"
DEV_DOC_DIR = REPO_ROOT / "docs/developer"


def git_remote_https(repo_root: Path) -> str:
    try:
        raw = subprocess.check_output(
            ["git", "remote", "get-url", "origin"],
            cwd=repo_root,
            text=True,
        ).strip()
    except subprocess.CalledProcessError as err:
        raise SystemExit(f"Unable to read git remote: {err}") from err

    if raw.endswith(".git"):
        raw = raw[:-4]
    if raw.startswith("git@github.com:"):
        owner_repo = raw.split(":", 1)[1]
        return f"https://github.com/{owner_repo}"
    if raw.startswith("https://"):
        return raw

    raise SystemExit(f"Unsupported git remote format: {raw}")


def rewrite_links(text: str, dev_en_url: str, dev_es_url: str) -> str:
    updated = text.replace("(docs/developer/README.dev.md)", f"({dev_en_url})")
    updated = updated.replace("(docs/developer/README.dev.es.md)", f"({dev_es_url})")
    updated = updated.replace(
        f"({dev_en_url.replace('/blob/development/', '/blob/beta-release/')})",
        f"({dev_en_url})",
    )
    updated = updated.replace(
        f"({dev_es_url.replace('/blob/development/', '/blob/beta-release/')})",
        f"({dev_es_url})",
    )
    lines = [line for line in updated.splitlines() if "install-scanner.sh" not in line]
    result = "\n".join(lines)
    if updated.endswith("\n"):
        result += "\n"
    return result


def stage_paths(paths: Iterable[Path]) -> None:
    for path in paths:
        subprocess.run(["git", "add", str(path)], cwd=REPO_ROOT, check=False)


def main() -> None:
    repo_url = git_remote_https(REPO_ROOT)
    dev_en = f"{repo_url}/blob/development/docs/developer/README.dev.md"
    dev_es = f"{repo_url}/blob/development/docs/developer/README.dev.es.md"

    if DEV_DOC_DIR.exists():
        subprocess.run(["git", "rm", "-r", "--quiet", str(DEV_DOC_DIR.relative_to(REPO_ROOT))], cwd=REPO_ROOT, check=False)

    for path in TARGET_FILES:
        if not path.exists():
            continue
        original = path.read_text(encoding="utf-8")
        rewritten = rewrite_links(original, dev_en, dev_es)
        if rewritten != original:
            path.write_text(rewritten, encoding="utf-8")
            subprocess.run(["git", "add", str(path.relative_to(REPO_ROOT))], cwd=REPO_ROOT, check=False)

    if INDEX_FILE.exists():
        original = INDEX_FILE.read_text(encoding="utf-8")
        rewritten = original.replace("`../README.dev.md`", f"<{dev_en}>")
        rewritten = rewritten.replace("`../README.dev.es.md`", f"<{dev_es}>")
        if rewritten != original:
            INDEX_FILE.write_text(rewritten, encoding="utf-8")
            subprocess.run(["git", "add", str(INDEX_FILE.relative_to(REPO_ROOT))], cwd=REPO_ROOT, check=False)

    print("Prepared release docs.")


if __name__ == "__main__":
    main()
