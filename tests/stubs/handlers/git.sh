#!/usr/bin/env bash
# git stub to emulate minimal behaviour required by tests.
# Controlled by:
#   GIT_STUB_CLONE_SOURCE : directory whose contents will be copied during clone
#   GIT_STUB_DESCRIBE      : output for `git describe --long --tags`
#   GIT_STUB_DESCRIBE_RC   : exit status for describe (default 0)
#   GIT_STUB_REV_COUNT     : output for `git rev-list --count HEAD`
#   GIT_STUB_REV_PARSE     : output for `git rev-parse --short HEAD`

set -euo pipefail

if [[ $# -ge 1 && "$1" == "clone" ]]; then
  shift
  # we only care about last argument as destination
  dest="${@: -1}"
  src="${GIT_STUB_CLONE_SOURCE:-}"
  if [[ -z "$src" ]]; then
    echo "[git-stub] clone source not set" >&2
    exit 2
  fi
  mkdir -p "$dest"
  cp -R "$src"/. "$dest"/
  exit 0
fi

if [[ $# -ge 3 && "$1" == "describe" ]]; then
  printf '%s\n' "${GIT_STUB_DESCRIBE:-v0.0.0-0-gstub}" \
    && exit "${GIT_STUB_DESCRIBE_RC:-0}"
fi

if [[ $# -ge 4 && "$1" == "rev-list" ]]; then
  printf '%s\n' "${GIT_STUB_REV_COUNT:-42}"
  exit 0
fi

if [[ $# -ge 3 && "$1" == "rev-parse" ]]; then
  printf '%s\n' "${GIT_STUB_REV_PARSE:-deadbeef}"
  exit 0
fi

# default to success
exit 0
