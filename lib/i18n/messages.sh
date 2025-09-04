#!/usr/bin/env bash
# messages.sh — Language detection and simple translations (en/es)

i18n_detect_lang() {
  local l="${LC_ALL:-${LC_MESSAGES:-${LANG:-en}}}"
  case "$l" in es*|ES*) echo es;; *) echo en;; esac
}

REPORT_LANG="${REPORT_LANG:-$(i18n_detect_lang)}"

i18n_translate_item() { # $1=item_key
  case "$1" in
    item_pkgb_source)          [ "$REPORT_LANG" = es ] && echo "Origen del PKGBUILD" || echo "PKGBUILD Source";;
    item_plain_availability)   [ "$REPORT_LANG" = es ] && echo "Disponibilidad de PKGBUILD plano" || echo "Plain PKGBUILD availability";;
    item_vcs_pinning)          [ "$REPORT_LANG" = es ] && echo "Fijación de VCS" || echo "VCS pinning";;
    item_source_urls)          [ "$REPORT_LANG" = es ] && echo "URLs de origen" || echo "Source URLs";;
    item_allowed_domains)      [ "$REPORT_LANG" = es ] && echo "Dominios permitidos" || echo "Allowed domains";;
    item_checksums)            echo "Checksums";;
    item_red_flags)            [ "$REPORT_LANG" = es ] && echo "Banderas rojas (estático)" || echo "Static red flags";;
    item_makepkg_verifysource) echo "makepkg --verifysource";;
    item_js_sources)           [ "$REPORT_LANG" = es ] && echo "Fuentes (JS parser)" || echo "Sources (JS parser)";;
    item_js_git_pinning)       [ "$REPORT_LANG" = es ] && echo "Fijación de git (JS)" || echo "Git pinning (JS)";;
    item_js_https)             [ "$REPORT_LANG" = es ] && echo "HTTPS en fuentes (JS)" || echo "Sources over HTTPS (JS)";;
    item_js_redflags)          [ "$REPORT_LANG" = es ] && echo "Banderas rojas (JS)" || echo "Red flags (JS)";;
    *) echo "$1";;
  esac
}

i18n_translate_msg() { # $1=msg_key
  case "$1" in
    source_plain)             [ "$REPORT_LANG" = es ] && echo "PKGBUILD plano desde AUR" || echo "AUR plain PKGBUILD";;
    source_snapshot)          [ "$REPORT_LANG" = es ] && echo "Snapshot .tar.gz desde AUR" || echo "AUR snapshot tarball";;
    source_git)               [ "$REPORT_LANG" = es ] && echo "Clonado desde AUR (fallback)" || echo "AUR git clone (fallback)";;
    plain_missing_warn)       [ "$REPORT_LANG" = es ] && echo "PKGBUILD plano no disponible (advertencia)" || echo "Plain PKGBUILD unavailable (warning)";;
    plain_missing_fail)       [ "$REPORT_LANG" = es ] && echo "PKGBUILD plano no disponible (estricto)" || echo "Plain PKGBUILD unavailable (strict)";;
    vcs_pinned_ok)            [ "$REPORT_LANG" = es ] && echo "Todas las fuentes VCS fijadas (o no hay)" || echo "All VCS sources pinned (or none present)";;
    vcs_unpinned_warn)        [ "$REPORT_LANG" = es ] && echo "Hay fuentes git+ sin #commit= o #tag=" || echo "Some git+ sources are not pinned";;
    vcs_unpinned_fail)        [ "$REPORT_LANG" = es ] && echo "Fuentes git+ sin fijar (añade #commit= o #tag=)" || echo "Unpinned git+ sources (add #commit= or #tag=)";;
    urls_https_ok)            [ "$REPORT_LANG" = es ] && echo "Todas las fuentes usan HTTPS" || echo "All sources use HTTPS";;
    urls_https_warn)          [ "$REPORT_LANG" = es ] && echo "Hay URLs no-HTTPS (desaconsejado)" || echo "Found non-HTTPS URLs (discouraged)";;
    urls_https_fail)          [ "$REPORT_LANG" = es ] && echo "URLs no-HTTPS (prohibido en STRICT)" || echo "Found non-HTTPS URLs (forbidden in STRICT)";;
    domains_ok)               [ "$REPORT_LANG" = es ] && echo "Todos los dominios están en la lista" || echo "All source domains are in the whitelist";;
    domains_warn)             [ "$REPORT_LANG" = es ] && echo "Dominios fuera de la lista permitida" || echo "Source domains outside whitelist";;
    domains_fail)             [ "$REPORT_LANG" = es ] && echo "Dominios no permitidos (STRICT)" || echo "Source domains not in whitelist (STRICT)";;
    sum_weak_fail)            [ "$REPORT_LANG" = es ] && echo "Sumas débiles (md5/sha1) o SKIP (STRICT)" || echo "Weak sums (md5/sha1) or SKIP (STRICT)";;
    sum_autofixed_ok)         [ "$REPORT_LANG" = es ] && echo "Sumas débiles reemplazadas por sha256sums" || echo "Weak sums replaced with sha256sums";;
    sum_autofixed_skipfast)   [ "$REPORT_LANG" = es ] && echo "Sumas débiles; FAST=1 impide autocorrección" || echo "Weak sums; FAST=1 skipped auto-upgrade";;
    sum_autofixed_skipverifyonly) [ "$REPORT_LANG" = es ] && echo "Sumas débiles; VERIFY_ONLY=1 evita descargas" || echo "Weak sums; VERIFY_ONLY=1 avoids downloads";;
    sum_autofixed_fail)       [ "$REPORT_LANG" = es ] && echo "No fue posible generar sha256sums" || echo "Could not generate sha256sums";;
    sum_missing_strict)       [ "$REPORT_LANG" = es ] && echo "Sin sumas fuertes (sha256/sha512) (STRICT)" || echo "No strong sums (sha256/sha512) declared (STRICT)";;
    sum_missing_fast)         [ "$REPORT_LANG" = es ] && echo "Sin sumas fuertes; FAST=1 omitió añadir sha256sums" || echo "No strong sums; FAST=1 skipped adding sha256sums";;
    redflags_ok)              [ "$REPORT_LANG" = es ] && echo "Sin patrones sospechosos" || echo "No suspicious patterns detected";;
    redflags_warn)            [ "$REPORT_LANG" = es ] && echo "Se detectaron patrones sospechosos" || echo "Suspicious patterns found";;
    redflags_warn_arch_eval)  [ "$REPORT_LANG" = es ] && echo "Eval usado para elegir archivo según arquitectura de CPU (riesgo bajo)" || echo "Eval used to select file by CPU architecture (low risk)";;
    redflags_fail)            [ "$REPORT_LANG" = es ] && echo "Patrones sospechosos (STRICT)" || echo "Suspicious patterns found (STRICT)";;
    js_git_pinned_ok)         [ "$REPORT_LANG" = es ] && echo "Fuentes git fijadas (JS)" || echo "Git sources pinned (JS)";;
    js_git_unpinned_warn)     [ "$REPORT_LANG" = es ] && echo "Hay git sin fijar (JS)" || echo "Unpinned git sources (JS)";;
    js_git_unpinned_fail)     [ "$REPORT_LANG" = es ] && echo "git sin fijar (STRICT, JS)" || echo "Unpinned git sources (STRICT, JS)";;
    js_https_ok)              [ "$REPORT_LANG" = es ] && echo "Todas las fuentes usan HTTPS (JS)" || echo "All sources use HTTPS (JS)";;
    js_https_warn)            [ "$REPORT_LANG" = es ] && echo "Fuentes no-HTTPS (JS)" || echo "Non-HTTPS sources (JS)";;
    js_https_fail)            [ "$REPORT_LANG" = es ] && echo "Fuentes no-HTTPS (STRICT, JS)" || echo "Non-HTTPS sources (STRICT, JS)";;
    js_redflags_ok)           [ "$REPORT_LANG" = es ] && echo "Sin banderas rojas (JS)" || echo "No red flags (JS)";;
    js_redflags_warn)         [ "$REPORT_LANG" = es ] && echo "Banderas rojas detectadas (JS)" || echo "Red flags detected (JS)";;
    js_redflags_fail)         [ "$REPORT_LANG" = es ] && echo "Banderas rojas (STRICT, JS)" || echo "Red flags (STRICT, JS)";;
    sources_*)                echo "$1";;
    verifysource_skip_verifyonly) [ "$REPORT_LANG" = es ] && echo "No se ejecutó (solo verificación). Usa DEEP=1" || echo "Not run (verify-only). Set DEEP=1";;
    verifysource_skip_fast)   [ "$REPORT_LANG" = es ] && echo "Omitido por --fast" || echo "Skipped by --fast";;
    verifysource_fail)        [ "$REPORT_LANG" = es ] && echo "Comprobación de integridad/PGP falló" || echo "Integrity/PGP check failed";;
    verifysource_fail_strict) [ "$REPORT_LANG" = es ] && echo "Comprobación de integridad/PGP falló (STRICT)" || echo "Integrity/PGP check failed (STRICT)";;
    verifysource_ok)          [ "$REPORT_LANG" = es ] && echo "Todas las fuentes verificadas" || echo "All sources verified";;
    *) echo "$1";;
  esac
}

i18n_translate_status() { # $1=PASS|WARN|FAIL|SKIP
  case "$1" in
    PASS) [ "$REPORT_LANG" = es ] && echo "OK" || echo "PASS";;
    WARN) [ "$REPORT_LANG" = es ] && echo "ADVERTENCIA" || echo "WARN";;
    FAIL) [ "$REPORT_LANG" = es ] && echo "FALLA" || echo "FAIL";;
    SKIP) [ "$REPORT_LANG" = es ] && echo "OMITIDO" || echo "SKIP";;
  esac
}

i18n_translate_misc() { # $1=title|overall|action_install|action_noinstall|action_verify_only|bar_end
  case "$1" in
    title)            [ "$REPORT_LANG" = es ] && echo "==== Resumen de verificación AUR ====" || echo "==== AUR Verification Summary ====";;
    overall)          [ "$REPORT_LANG" = es ] && echo "Resultado" || echo "Overall";;
    action_install)   [ "$REPORT_LANG" = es ] && echo "Acción: Instalando con yay" || echo "Action: Installing with yay";;
    action_noinstall) [ "$REPORT_LANG" = es ] && echo "Acción: No se instala por fallas" || echo "Action: Not installing due to failures";;
    action_verify_only) [ "$REPORT_LANG" = es ] && echo "Acción: Solo verificación (sin instalar)" || echo "Action: Verification only (no install)";;
    bar_end)          echo "=================================";;
  esac
}

