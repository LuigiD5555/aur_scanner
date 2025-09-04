#!/usr/bin/env bash
# License: CC BY-NC-SA 4.0 (https://creativecommons.org/licenses/by-nc-sa/4.0/)
# Copyright (c) 2025 José Luis López López Prieto
# render_summary.sh — Simple reporting for verification results (uses i18n messages)

report_init() {
  REPORT_ITEMS=()
  REPORT_FAILS=0
  REPORT_WARNS=0
}

report_add() { # $1=item_key  $2=STATUS  $3=msg_key
  REPORT_ITEMS+=("$1|$2|$3")
  case "$2" in
    FAIL) REPORT_FAILS=$((REPORT_FAILS+1));;
    WARN) REPORT_WARNS=$((REPORT_WARNS+1));;
  esac
}

report_print() { # $1=install|verify-only
  printf '\n%s\n' "$(i18n_translate_misc title)" >&2
  local line item status msg
  for line in "${REPORT_ITEMS[@]}"; do
    item="${line%%|*}"; status="${line#*|}"; status="${status%%|*}"; msg="${line##*|}"
    printf ' - %s: %s — %s\n' "$(i18n_translate_item "$item")" "$(i18n_translate_status "$status")" "$(i18n_translate_msg "$msg")" >&2
  done
  local overall
  if [ "$REPORT_FAILS" -gt 0 ]; then
    overall="FAIL"
  elif [ "$REPORT_WARNS" -gt 0 ]; then
    overall="OK (with warnings)"
  else
    overall="OK"
  fi
  printf ' - %s: %s\n' "$(i18n_translate_misc overall)" "$overall" >&2
  if [ "$1" = "install" ]; then
    if [ "$overall" = "OK" ] || [ "$overall" = "OK (with warnings)" ]; then
      printf ' - %s\n' "$(i18n_translate_misc action_install)" >&2
    else
      printf ' - %s\n' "$(i18n_translate_misc action_noinstall)" >&2
    fi
  else
    printf ' - %s\n' "$(i18n_translate_misc action_verify_only)" >&2
  fi
  printf '%s\n\n' "$(i18n_translate_misc bar_end)" >&2
}
