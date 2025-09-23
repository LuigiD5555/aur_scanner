# SPDX-License-Identifier: MIT
# Copyright (c) 2025 José Luis López López Prieto
# Author GitHub: https://github.com/LuigiD5555
# vcs_pinning_rule.sh — enforce pinning for VCS (git+) sources

# rule_vcs_pinning $1=pkgb_path $2=strict(0|1)
# Produces a report item: PASS / WARN / FAIL and exit code 0/1.
rule_vcs_pinning() {
  local pkgb="$1"
  local strict="${2:-0}"

  local pinned=0

  if declare -F pkgb_check_vcs_pinning >/dev/null 2>&1; then
    # Use the canonical parser check if available
    if pkgb_check_vcs_pinning "$pkgb"; then
      pinned=1
    fi
  else
    # Lightweight fallback if the function is not available
    if grep -Eq '(^|[^a-zA-Z0-9_])(source|_sources)=.*git\+' "$pkgb"; then
      # Consider pinned if the fragment includes #commit= or #tag=
      if grep -Eq 'git\+.*(#(commit|tag)=[A-Za-z0-9._-]+)' "$pkgb"; then
        pinned=1
      fi
    else
      # No VCS sources present: treat as pinned/irrelevant
      pinned=1
    fi
  fi

  if (( pinned )); then
    report_add "item_vcs_pinning" "PASS" "vcs_pinned_ok"
    return 0
  else
    if [[ "$strict" == "1" ]]; then
      report_add "item_vcs_pinning" "FAIL" "vcs_unpinned_fail"
      return 1
    else
      report_add "item_vcs_pinning" "WARN" "vcs_unpinned_warn"
      return 0
    fi
  fi
}
