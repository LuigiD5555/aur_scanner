#!/usr/bin/env bash
# SPDX-License-Identifier: MIT
# Copyright (c) 2025 José Luis López López Prieto
# Author GitHub: https://github.com/LuigiD5555
# functions_summary.sh — extract prepare/build/package() function snippets

print_func_summaries() {
  awk '
    /^prepare\(\)/ {inp=1; print "---- prepare() ----"; next}
    /^build\(\)/   {inb=1; print "---- build() ----";   next}
    /^package\(\)/ {inpkg=1; print "---- package() ----";next}
    inp && /^\}/ {inp=0} inb && /^\}/ {inb=0} inpkg && /^\}/ {inpkg=0}
    inp||inb||inpkg { print }
  ' "$1" | sed 's/^[[:space:]]\{0,2\}//'
}
