#!/usr/bin/env bash
# License: CC BY-NC-SA 4.0 (https://creativecommons.org/licenses/by-nc-sa/4.0/)
# Copyright (c) 2025 José Luis López López Prieto
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
