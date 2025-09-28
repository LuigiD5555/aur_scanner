#!/usr/bin/env bash
set -euo pipefail

SOURCE_BRANCH=${SOURCE_BRANCH:-development}
TARGET_BRANCH=${TARGET_BRANCH:-beta-release}
PROTECTED_PATHS=${PROTECTED_PATHS:-packaging/aur-scanner-git}
COMMIT_MESSAGE=${COMMIT_MESSAGE:-"ci: sync ${SOURCE_BRANCH} into ${TARGET_BRANCH}"}

if [[ -z ${GITHUB_WORKSPACE:-} ]]; then
  echo "[sync] Running outside GitHub Actions; ensure you are in repo root." >&2
fi

# Fetch the latest refs for both branches.
git fetch --prune origin "$TARGET_BRANCH" "$SOURCE_BRANCH"

# If TARGET already contains SOURCE commits, skip.
if git rev-list --count "origin/${TARGET_BRANCH}..origin/${SOURCE_BRANCH}" | grep -qx '0'; then
  echo "[sync] ${TARGET_BRANCH} already contains ${SOURCE_BRANCH}; nothing to do." >&2
  exit 0
fi

# Prepare a working branch based on the target branch.
git checkout -B sync-${SOURCE_BRANCH}-into-${TARGET_BRANCH} "origin/${TARGET_BRANCH}"

# Stage a merge without committing so we can adjust protected paths.
if ! git merge --no-ff --no-commit "origin/${SOURCE_BRANCH}"; then
  echo "[sync] Merge produced conflicts. Resolve manually." >&2
  exit 1
fi

# Restore protected paths from the original target branch tip.
read -r -a protected <<<"${PROTECTED_PATHS}"
for path in "${protected[@]}"; do
  [[ -z "$path" ]] && continue
  if git rev-parse --verify "HEAD:$path" >/dev/null 2>&1 || git ls-files -- "$path" >/dev/null 2>&1; then
    git restore --source=HEAD --staged --worktree -- "$path"
  fi
done

# If nothing besides protected paths changed, abort the merge gracefully.
if git diff --cached --quiet; then
  echo "[sync] No effective changes after protecting paths; aborting merge." >&2
  git merge --abort
  exit 0
fi

# Commit the merge.
git commit -m "$COMMIT_MESSAGE"

echo "[sync] Merge commit prepared for ${TARGET_BRANCH}." >&2
