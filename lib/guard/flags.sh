# SPDX-License-Identifier: MIT
# Copyright (c) 2025 José Luis López López Prieto
# Author GitHub: https://github.com/LuigiD5555
# lib/guard/flags.sh
# Wrapper-only flags: consume and set env vars

# Export environment variables only if they are set
guard_export_if_set() {
  local n
  for n in "$@"; do
    [[ -n "${!n:-}" ]] && export "$n"
  done
}

# Consume wrapper-only flags and set env vars.
# Input:  argv...
# Output: FILTERED_ARGS (global array) with non-wrapper args
guard_consume_wrapper_flags() {
  local -a in_args=("$@")
  local -a out_args=()
  local i=0 arg key val

  while (( i < ${#in_args[@]} )); do
    arg="${in_args[i]}"

    if [[ "$arg" == --* ]]; then
      key="$arg"; val=""
      if [[ "$arg" == *=* ]]; then
        key="${arg%%=*}"
        val="${arg#*=}"
      fi

      case "$key" in
        # ---- Boolean wrapper flags ----
        --verify-only)   VERIFY_ONLY=1;                         i=$((i+1)); continue ;;
        --deep)          DEEP=1;                                i=$((i+1)); continue ;;
        --fast)          FAST=1;                                i=$((i+1)); continue ;;
        --strict)        STRICT=1;                              i=$((i+1)); continue ;;
        --verbose)       VERBOSE=1; SHOW_FUNCS=1; SHOW_METADATA=1; i=$((i+1)); continue ;;
        --quiet)         QUIET=1;                               i=$((i+1)); continue ;;
        --metadata)      SHOW_METADATA=1;                       i=$((i+1)); continue ;;
        --ipv4|--force-ipv4)
                         AUR_FORCE_IPV4=1;                      i=$((i+1)); continue ;;

        # ---- Flags with value: '--opt value' or '--opt=value' ----
        --report-lang)
          if [[ -z "$val" ]]; then
            val="${in_args[i+1]:-}"; [[ -n "$val" ]] && i=$((i+1))
          fi
          REPORT_LANG="$val";                                   i=$((i+1)); continue ;;
        --report-lang=*)
          REPORT_LANG="$val";                                   i=$((i+1)); continue ;;

        --yay-bin|--helper-bin)
          if [[ -z "$val" ]]; then
            val="${in_args[i+1]:-}"; [[ -n "$val" ]] && i=$((i+1))
          fi
          YAY_BIN="$val";                                       i=$((i+1)); continue ;;
        --yay-bin=*|--helper-bin=*)
          YAY_BIN="$val";                                       i=$((i+1)); continue ;;

        # ---- Internal wrapper controls (not forwarded) ----
        --scan-debug) GUARD_DEBUG=1;                            i=$((i+1)); continue ;;
        --scan-help|--scan-list-helpers|--list-helpers|--help)
          # Optionally, show wrapper help here and exit 0.
          # echo "scan help..."; exit 0
          i=$((i+1)); continue ;;
      esac
    fi

    # Not a consumed wrapper flag: keep it for the helper (short/long/positional)
    out_args+=("$arg")
    i=$((i+1))
  done

  FILTERED_ARGS=("${out_args[@]}")
}
