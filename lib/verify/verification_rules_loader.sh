# SPDX-License-Identifier: MIT
# Copyright (c) 2025 José Luis López López Prieto <ing.jlllopezp@gmail.com>
# Author GitHub: https://github.com/LuigiD5555
# verification_rules_loader.sh — aggregate verification rules

# Expect pkgb helpers and logging/report to be already sourced by the caller.

SCRIPT_DIR=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)
source "$SCRIPT_DIR/../rules/vcs_pinning_rule.sh"
source "$SCRIPT_DIR/../rules/sources_rule.sh"
source "$SCRIPT_DIR/../rules/checksums_rule.sh"
source "$SCRIPT_DIR/../rules/js_signals_rule.sh"
source "$SCRIPT_DIR/../rules/redflags_rule.sh"
source "$SCRIPT_DIR/../rules/verifysource_rule.sh"
