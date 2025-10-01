#!/usr/bin/env bash
set -euo pipefail

SOURCE_BRANCH=${SOURCE_BRANCH:-development}
TARGET_BRANCH=${TARGET_BRANCH:-beta-release}
PROTECTED_PATHS=${PROTECTED_PATHS:-packaging/aur-scanner-git}
COMMIT_MESSAGE=${COMMIT_MESSAGE:-"chore(beta): sync ${SOURCE_BRANCH} into ${TARGET_BRANCH}"}
DEV_ONLY_PATHS_DEFAULT=$'tests\nscripts/run-tests.sh\nscripts/sync-development.sh\ndocs/developer'
DEV_ONLY_PATHS=${DEV_ONLY_PATHS:-$DEV_ONLY_PATHS_DEFAULT}
WORKTREE_PREFIX=${WORKTREE_PREFIX:-sync-${SOURCE_BRANCH}-into-${TARGET_BRANCH}}

repo_root=$(git rev-parse --show-toplevel)
if [[ -z ${GITHUB_WORKSPACE:-} ]]; then
  echo "[sync] Running outside GitHub Actions; ensure you are in repo root." >&2
fi

cleanup() {
  local status=$?
  if [[ -n ${worktree_dir:-} && -d ${worktree_dir:-} ]]; then
    git worktree remove --force "$worktree_dir" >/dev/null 2>&1 || true
  fi
  if [[ -n ${work_branch:-} ]]; then
    git branch -D "$work_branch" >/dev/null 2>&1 || true
  fi
  if [[ -n ${protected_tmp:-} && -d ${protected_tmp:-} ]]; then
    rm -rf "$protected_tmp"
  fi
  if [[ -n ${rsync_tmp:-} && -d ${rsync_tmp:-} ]]; then
    rm -rf "$rsync_tmp"
  fi
  exit "$status"
}
trap cleanup EXIT

map_input_to_array() {
  local __var=$1
  local __input=$2
  if [[ -z "$__input" ]]; then
    eval "$__var=()"
    return
  fi
  if [[ "$__input" == *$'\n'* ]]; then
    mapfile -t "$__var" < <(printf '%s\n' "$__input" | sed '/^$/d')
  else
    read -r -a "$__var" <<<"$__input"
  fi
}

map_input_to_array protected_paths "$PROTECTED_PATHS"
map_input_to_array dev_only_paths "$DEV_ONLY_PATHS"

if [[ ${#protected_paths[@]} -eq 0 ]]; then
  echo "[sync] No protected paths configured." >&2
fi

git fetch --prune origin "$SOURCE_BRANCH" "$TARGET_BRANCH"

if git rev-list --count "origin/${TARGET_BRANCH}..origin/${SOURCE_BRANCH}" | grep -qx '0'; then
  echo "[sync] ${TARGET_BRANCH} already contains ${SOURCE_BRANCH}; verifying pruning only." >&2
fi

timestamp=$(date +%Y%m%d%H%M%S)
work_branch="${WORKTREE_PREFIX}-${timestamp}"
worktree_dir=$(mktemp -d -t "${WORKTREE_PREFIX}-${timestamp}-XXXX")
protected_tmp=$(mktemp -d -t "protected-${TARGET_BRANCH}-${timestamp}-XXXX")
rsync_tmp=$(mktemp -d -t "rsync-${TARGET_BRANCH}-${timestamp}-XXXX")

# Prepare a local branch tracking the remote target tip.
git branch -f "$work_branch" "origin/${TARGET_BRANCH}" >/dev/null 2>&1

git worktree add "$worktree_dir" "$work_branch" >/dev/null

echo "[sync] Preparing protected paths snapshot." >&2
for path in "${protected_paths[@]}"; do
  [[ -z "$path" ]] && continue
  if [[ -e "$worktree_dir/$path" ]]; then
    mkdir -p "$protected_tmp/$(dirname "$path")"
    if [[ -d "$worktree_dir/$path" ]]; then
      rsync -a --delete "$worktree_dir/$path/" "$protected_tmp/$path/"
    else
      cp -a "$worktree_dir/$path" "$protected_tmp/$path"
    fi
  else
    echo "[sync] Protected path '$path' not present in target; skipping snapshot." >&2
  fi
done

# Mirror development tree into the worktree, excluding .git
rsync -a --delete \
  --exclude '.git' \
  --exclude '.git/' \
  "${repo_root}/" "$worktree_dir/"

echo "[sync] Restoring protected paths." >&2
for path in "${protected_paths[@]}"; do
  [[ -z "$path" ]] && continue
  if [[ -e "$protected_tmp/$path" ]]; then
    rm -rf "$worktree_dir/$path"
    mkdir -p "$worktree_dir/$(dirname "$path")"
    if [[ -d "$protected_tmp/$path" ]]; then
      rsync -a --delete "$protected_tmp/$path/" "$worktree_dir/$path/"
    else
      cp -a "$protected_tmp/$path" "$worktree_dir/$path"
    fi
  fi
done

pushd "$worktree_dir" >/dev/null

if [[ -x .github/scripts/prepare_release_docs.py ]]; then
  python3 .github/scripts/prepare_release_docs.py
elif [[ -f .github/scripts/prepare_release_docs.py ]]; then
  python3 .github/scripts/prepare_release_docs.py
fi

for path in "${dev_only_paths[@]}"; do
  [[ -z "$path" ]] && continue
  rm -rf -- "$path"
  git rm -rf --cached "$path" >/dev/null 2>&1 || true
done

git add -A

if git diff --cached --quiet; then
  echo "[sync] No changes detected for ${TARGET_BRANCH}." >&2
  popd >/dev/null
  exit 0
fi

git commit -m "$COMMIT_MESSAGE"

git push origin HEAD:"${TARGET_BRANCH}"

popd >/dev/null

trap - EXIT
cleanup
