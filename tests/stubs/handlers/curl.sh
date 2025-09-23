#!/usr/bin/env bash
# curl stub driven by environment.
# Variables:
#   CURL_STUB_FILEMAP : newline separated "url::/path/to/file" entries
#   CURL_STUB_FAIL    : newline separated urls that should fail

set -euo pipefail

outfile=""
head_mode=0
args=()
while [[ $# -gt 0 ]]; do
  case "$1" in
    -o)
      outfile="$2"
      shift 2
      ;;
    -O)
      outfile="$(basename "$2")"
      shift 2
      ;;
    -I|--head)
      head_mode=1
      shift
      ;;
    -A|-H|-L|--fail|--silent|--show-error|--location|--compressed|--connect-timeout|--max-time|--ipv4|-s|-S)
      # options with value or without; handle carefully
      if [[ "$1" =~ ^(-A|-H|--connect-timeout|--max-time)$ ]]; then
        shift 2
      else
        shift
      fi
      ;;
    *)
      args+=("$1")
      shift
      ;;
  esac
done

if [[ ${#args[@]} -eq 0 ]]; then
  echo "[curl-stub] missing URL" >&2
  exit 96
fi

url="${args[-1]}"

if [[ -n "${CURL_STUB_FAIL:-}" ]]; then
  while IFS= read -r line; do
    [[ -z "$line" ]] && continue
    if [[ "$url" == "$line" ]]; then
      echo "[curl-stub] forced failure for $url" >&2
      exit 22
    fi
  done <<< "${CURL_STUB_FAIL}"
fi

response=""
if [[ -n "${CURL_STUB_FILEMAP:-}" ]]; then
  while IFS= read -r line; do
    [[ -z "$line" ]] && continue
    case "$line" in
      *::*)
        map_url="${line%%::*}"
        map_file="${line##*::}"
        if [[ "$map_url" == "$url" ]]; then
          response="$map_file"
          break
        fi
        ;;
    esac
  done <<< "${CURL_STUB_FILEMAP}"
fi

if [[ -z "$response" ]]; then
  echo "[curl-stub] no response configured for $url" >&2
  exit 23
fi

if [[ "$head_mode" -eq 1 ]]; then
  if [[ -n "$outfile" ]]; then
    : >"$outfile"
  fi
  exit 0
fi

if [[ -n "$outfile" ]]; then
  cp "$response" "$outfile"
else
  cat "$response"
fi
