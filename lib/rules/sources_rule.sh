# SPDX-License-Identifier: MIT
# Copyright (c) 2025 José Luis López López Prieto <ing.jlllopezp@gmail.com>
# Author GitHub: https://github.com/LuigiD5555
# sources_rule.sh — enforce HTTPS-only and allowed domains

rule_sources() { # $1=pkgb $2=strict -> HTTPS + domains
  local pkgb="$1" strict="$2" sources
  sources="$(sed -n 'p' "$pkgb" | list_sources || true)"
  [ -z "$sources" ] && return 0

  if ! printf '%s\n' "$sources" | sources_have_only_https; then
    if [ "${VERBOSE:-0}" = "1" ]; then
      log_warn "All sources (marking non-HTTPS):"
      printf '%s\n' "$sources" | awk '{p=$0; if ($0 !~ /^https:\/\//) p="[non-https] " p; print "  " p}' >&2
    else
      log_warn "Non-HTTPS sources detected:"; printf '%s\n' "$sources" | awk '!/^https:/' | sed 's/^/  /' >&2
    fi
    if [ "$strict" = "1" ]; then
      report_add "item_source_urls" "FAIL" "urls_https_fail"; return 1
    else
      report_add "item_source_urls" "WARN" "urls_https_warn"
    fi
  else
    report_add "item_source_urls" "PASS" "urls_https_ok"
  fi

  if ! printf '%s\n' "$sources" | sources_domains_allowed; then
    if [ "${VERBOSE:-0}" = "1" ]; then
      log_warn "All sources (marking non-allowed domains):"
      printf '%s\n' "$sources" | awk -v re="$ALLOWED_DOMAINS" 'BEGIN{IGNORECASE=0} {ok=($0 ~ re); p=$0; if (!ok) p="[non-allowed] " p; print "  " p}' >&2
    else
      log_warn "Sources from non-allowed domains:"; printf '%s\n' "$sources" | grep -Ev "$ALLOWED_DOMAINS" | sed 's/^/  /' >&2 || true
    fi
    if [ "$strict" = "1" ]; then
      report_add "item_allowed_domains" "FAIL" "domains_fail"; return 1
    else
      report_add "item_allowed_domains" "WARN" "domains_warn"
    fi
  else
    report_add "item_allowed_domains" "PASS" "domains_ok"
  fi
}
