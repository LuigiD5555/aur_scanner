# Verificador AUR (Bash)

> **Verifica primero, instala después** — Verificador de seguridad para paquetes de AUR (y envolturas de GitHub) con instalación automática vía `yay` sólo si todo pasa.

<p align="left">
  <code>Arch</code> · <code>AUR</code> · <code>makepkg --verifysource</code> · <code>PGP</code> · <code>sha256</code> · <code>yay</code>
</p>

---

🌐 Read this in [English](README.md)

---

## 🧭 ¿Qué hace esta herramienta?

Esta herramienta en Bash toma un nombre de paquete AUR **o** una URL de GitHub y:

1) **Obtiene directamente desde AUR** usando los endpoints oficiales de snapshot/plain (sin `git clone`), o **detecta** el paquete AUR que envuelve una URL de GitHub. Si los endpoints snapshot/plain no están disponibles, cae a un `git clone` superficial.  
2) **Audita** el `PKGBUILD` con controles estáticos (banderas rojas comunes).  
3) **Verifica la integridad** de las fuentes con `makepkg --verifysource`.  
4) **Corrige** sumas débiles (p. ej. `sha1sums`/`SKIP`) reemplazándolas por `sha256sums` (sólo en modo normal).  
5) **(Opcional)** **Refuerza** la política en **modo estricto**: dominios permitidos, sin sumas débiles, y verificación PGP cuando hay `.sig`.  
6) Si todo está limpio, **instala** automáticamente con `yay -S` (salvo que uses `--verify-only`).

> Pensado para quienes no confían a ciegas en AUR: valida primero, instala después.

---

## 🚀 Uso rápido

Ejecuta el punto de entrada modular (recomendado):

- `sh ./bin/aur-verify <paquete|URL_de_GitHub>`
- o `bash bin/aur-verify <paquete|URL_de_GitHub>`

Instalar tras verificar un paquete AUR:

```bash
sh ./bin/aur-verify oreo-nord-cursors-git
```

Sólo verificar (no instalar):

```bash
sh ./bin/aur-verify --verify-only oreo-nord-cursors-git
```

Modo estricto (políticas más duras):

```bash
STRICT=1 sh ./bin/aur-verify oreo-nord-cursors-git
```

Verificación rápida (metadatos, sin descargas de `makepkg`):

```bash
FAST=1 sh ./bin/aur-verify <paquete-AUR>
```

Detectar y verificar a partir de un repositorio GitHub (busca el envoltorio AUR):

```bash
sh ./bin/aur-verify https://github.com/OWNER/REPO
```

Pre‑check antes de instalar (aur-guard):

- Invocación explícita (sin cambiar el PATH):

```bash
bin/aur-guard yay -S oreo-nord-cursors-git
bin/aur-guard paru -Syu oreo-nord-cursors-git
bin/aur-guard pikaur -S oreo-nord-cursors-git
bin/aur-guard trizen -S oreo-nord-cursors-git
bin/aur-guard pamac build oreo-nord-cursors-git
# pacman no instala AUR; el wrapper solo delega
bin/aur-guard pacman -S neovim
```

- Drop‑in tras crear el symlink a `~/.local/bin/yay`:

```bash
yay -S oreo-nord-cursors-git
paru -Syu oreo-nord-cursors-git
pikaur -S oreo-nord-cursors-git
trizen -S oreo-nord-cursors-git
pamac build oreo-nord-cursors-git
```

### Configuración automática

Ejecuta el instalador para crear los symlinks automáticamente y asegurar el orden en PATH:

```bash
bash scripts/install-aur-guard.sh            # modo usuario (recomendado)
# o
sudo bash scripts/install-aur-guard.sh --system  # a nivel sistema en /usr/local/bin
```

---

## 🧰 Wrapper de interceptación (aur-guard)

Si quieres forzar la verificación antes de usar tus helpers habituales (yay/paru/pamac), añade el wrapper universal y ponlo al principio del `PATH`:

```bash
# Opciones de instalación (elige una):
# 1) Invocación explícita
aur-guard yay -S <pkg1> <pkg2>

# 2) Symlinks en ~/.local/bin (recomendado)
mkdir -p ~/.local/bin
ln -sf "$(pwd)/bin/aur-guard" ~/.local/bin/yay
ln -sf "$(pwd)/bin/aur-guard" ~/.local/bin/paru
ln -sf "$(pwd)/bin/aur-guard" ~/.local/bin/pikaur
ln -sf "$(pwd)/bin/aur-guard" ~/.local/bin/trizen
ln -sf "$(pwd)/bin/aur-guard" ~/.local/bin/pamac
export PATH="$HOME/.local/bin:$PATH"

# Ahora usa tus comandos como siempre
yay -S <paquete-aur>
paru -S <paquete-aur>
pamac build <paquete-aur>
 
```

Cómo funciona

- Detecta los objetivos a instalar y verifica con `bin/aur-verify --verify-only` únicamente los que están en AUR (consulta RPC v5).
- Si alguna verificación falla, aborta y no ejecuta el helper real.
- Si todo pasa, delega al binario original con los mismos argumentos.
- Respeta variables como `STRICT=1`, `FAST=1`, `VERBOSE=1`, `QUIET=1` que afectan a `bin/aur-verify`.
- Para forzar ruta del binario real, define `AUR_GUARD_REAL_YAY=/usr/bin/yay` (análogamente para `PARU`, `PAMAC`, etc.).
- Para saltarse el wrapper puntualmente, usa `AUR_GUARD_BYPASS=1`.

Comportamiento por helper (transparente)

- El wrapper no cambia el comportamiento del helper; sólo hace pre-checks y delega con los mismos argumentos.
- pamac: se pre‑verifica únicamente con `pamac build` (AUR). `pamac install|upgrade` no se tocan.
- yay/paru/pikaur/trizen: pre‑check y delegación normal (estos tools manejan repos y AUR).

Flags de conveniencia (opcionales)

- Puedes pasar flags del verificador junto a los helpers; el wrapper los usa para el pre-check y los elimina antes de delegar:
  - `--strict` (equivalente a `STRICT=1`)
  - `--fast` (equivalente a `FAST=1`)
  - `--verbose` / `--quiet` (equivalente a `VERBOSE=1` / `QUIET=1`)
  - `--metadata` (equivalente a `SHOW_METADATA=1`)
  - `--verify-only` (ejecuta sólo el pre-check; no instala con el helper)

Nota para desarrolladores: lista de helpers

- Extiende `lib/guard/helpers.list` para añadir nuevos helpers o ajustar su tipo (`pacman` vs `pamac`).

Notas

- Puedes forzar la ruta del binario real con `AUR_GUARD_REAL_<HELPER>=/ruta/al/binario`.
- Para saltarse el wrapper puntualmente: `AUR_GUARD_BYPASS=1`.

---

## 📦 Requisitos

- Arch Linux o derivado con acceso a AUR.
- Herramientas: `git`, `curl`, `makepkg` (parte de `pacman`), y un ayudante AUR compatible: `yay` (por defecto).  
  - Puedes cambiar el binario de yay con `YAY_BIN=/ruta/a/yay`.

```bash
# No requiere instalación; invoca directo con sh o bash
```

---

## 🔧 Opciones y variables

**Flags**:

- `--verify-only` — Ejecuta verificaciones estáticas y sale sin instalar (**sin descargas**).
- `--deep` — En verify-only, también ejecuta `makepkg --verifysource` (descarga fuentes y verifica checksums/PGP).
- `--fast` — Verificaciones **sólo de metadatos** (omite `makepkg --verifysource`). ⚠️ En `STRICT=1` reduce garantías.
- `--verbose` — Muestra todos los detalles para usuarios avanzados (incluye resúmenes de funciones, metadatos del repositorio y más contexto en incidencias).
- `--quiet` — Logs mínimos (solo errores y el resumen final de verificación). Sobrescribe `--metadata`.
- `--metadata` — Muestra metadatos del repositorio (`yay -Si`) incluso en verify-only (oculto por defecto para mantenerlo veloz).
- `-h`/`--help` — Ayuda.

**Variables de entorno**:

- `STRICT=1` — Activa **modo estricto**:
  - **Prohíbe** `sha1`, `SKIP` o ausencia de sumas fuertes.
  - **Lista blanca de dominios** (por defecto): `github.com`, `codeload.github.com`, `objects.githubusercontent.com`, `gitlab.com`.
  - Si hay archivos `.sig` en `source=()`, **debe** pasar `makepkg --verifysource` (PGP).
  - Muestra un **resumen** de funciones `prepare()`, `build()`, `package()`.
- `YAY_BIN=/ruta/yay` — Cambia el binario de yay.

Reporte e idioma:

- El resumen final se imprime en el idioma de tu terminal (inglés por defecto; español si `LANG`/`LC_*` comienza con `es`).
- Puedes forzar el idioma con `REPORT_LANG=es` o `REPORT_LANG=en`.
 - `SHOW_FUNCS=1` — Mostrar resúmenes de `prepare()/build()/package()`; implícito con `--verbose`.
 - `SHOW_METADATA=1` — Mostrar metadatos en verify-only; implícito con `--verbose` (o usa `--metadata`).
 - `QUIET=1` — Equivalente a `--quiet`.

---

## 🧪 Modos de verificación y profundidad

Ajusta qué tan profunda es la verificación y cuánta salida se muestra:

- `--verify-only`: Por defecto solo checks estáticos (sin descargas ni instalación).  
  - Añade `DEEP=1` para ejecutar también `makepkg --verifysource` (descarga fuentes y verifica checksums/PGP).  
  - Útil para CI o cuando quieres verificar integridad sin instalar.
- `--fast`: Solo metadatos; omite `makepkg --verifysource` y cualquier descarga.  
  - Tiene precedencia sobre `DEEP=1` (si `FAST=1`, no habrá verificación profunda).
- `STRICT=1`: Endurece políticas (solo HTTPS, dominios permitidos, sumas fuertes, pinning) y convierte algunos WARN en FAIL.  
- `--verbose` / `--quiet`: Aumenta detalles (contexto completo, resúmenes de funciones) o minimiza logs (solo errores + resumen final).

Cuándo usar cada uno

- Triage rápido (sin descargas): `sh ./bin/aur-verify <paquete> --verify-only --fast`
- Integridad sin instalar: `DEEP=1 sh ./bin/aur-verify <paquete> --verify-only`
- Filtro estricto para sistemas sensibles: `STRICT=1 DEEP=1 sh ./bin/aur-verify <paquete> --verify-only`
- Auditoría detallada: `STRICT=1 sh ./bin/aur-verify <paquete> --verify-only --verbose`
- Mínimo ruido: `sh ./bin/aur-verify <paquete> --verify-only --quiet`

Notas

- La verificación profunda (`DEEP=1`) requiere red para bajar fuentes; se omite si se establece `--fast`.
- La instalación depende del veredicto final; si es FAIL y no estás en verify‑only, se aborta la instalación.

---

## 🧩 CLI Node: pkgb-parse (opcional)

El proyecto incluye un CLI modular en Node.js para parsear PKGBUILD con rapidez y aportar señales adicionales al reporte en Bash. Es opcional: si no hay Node, Bash usa heurísticas con grep/awk.

- Punto de entrada: `bin/pkgb-parse`
- Módulos: `lib/pkgb/parser/{analysis,utils,outputs,patterns,terminalColors}.js`

Ejemplos:

```bash
# Parsear desde archivo
node bin/pkgb-parse --file ./PKGBUILD --summary

# Parsear directo desde la URL plain de AUR
node bin/pkgb-parse --url "https://aur.archlinux.org/cgit/aur.git/plain/PKGBUILD?h=zotero"

# JSON para integraciones
node bin/pkgb-parse --file ./PKGBUILD --json
```

<details>
<summary><strong>Opciones del CLI (detalles)</strong></summary>

- `--file PATH`: Parsear PKGBUILD desde archivo local
- `--url URL`: Descargar y parsear PKGBUILD desde URL
- `--summary`: Resumen en una línea (nombre, versión, conteos)
- `--json`: Salida JSON estructurada
- `--signals`: Pares clave=valor para Bash
- `--redflags-lines`: Banderas rojas como `linea<TAB>contenido`
- `--sources-compact [--limit N]`: Lista compacta de fuentes, opcionalmente limitada

Tip: Si pasas un enlace de AUR que no es el endpoint “plain”, el CLI sugerirá la forma correcta `.../plain/PKGBUILD?h=<pkg>` y mostrará “Fetching from AUR (respectfully)...”.

</details>

---

## ✅ Qué comprueba

### 1) Banderas rojas en `PKGBUILD` (diagnóstico)

Busca patrones peligrosos o poco confiables, por ejemplo:

- **Descargas autoejecutadas**: `curl|wget ... (sh|bash)`
- **Sockets TCP en shell**: `/dev/tcp`
- **Ejecución dinámica**: `eval`, `$(...)`, `` `...` ``, `exec(`
- **Decodificación/descifrado** en línea: `base64 -d`, `openssl enc -d`
- **Privilegios/permiso sospechoso**: `chmod +s`, `setcap`, escritura sobre `/etc`
- **Trampas en rutas**: uso indebido de `pkgdir` apuntando a `/etc`
- **(STRICT)** one-liners con `python -c`, `perl -e`, `ruby -e`, `node -e`

Diagnóstico en `--verbose` (cuando hay Node): imprime líneas marcadas por el parser JS. Nota: el runner actual no añade un ítem de banderas rojas al resumen; la regla atómica `rule_red_flags` existe y puede invocarse de forma independiente.

<details>
<summary><strong>Severidad y patrones benignos comunes</strong></summary>

- En modo normal, las banderas rojas generan ADVERTENCIA; con `STRICT=1` pueden escalar a FALLA.
- Un caso frecuente de bajo riesgo es usar `eval` para resolver una variable según la arquitectura, por ejemplo:

  `python -m installer --destdir="$pkgdir" $(eval echo "\${_anki_whl_$CARCH}")`

  Esto resuelve una variable como `_anki_whl_x86_64`. Se mantiene como ADVERTENCIA en modo normal; en modo estricto sigue siendo FALLA.

- La verificación profunda (`DEEP=1`) no es necesaria para este caso; puede aumentar la confianza validando checksums/PGP vía `makepkg --verifysource`.

</details>

### 2) Dominios permitidos para `source=()`

- Acepta (por defecto): `github.com`, `codeload.github.com`, `objects.githubusercontent.com`, `gitlab.com`.
- En `STRICT=1`, **rechaza** cualquier otro dominio.

### 3) Políticas de checksums

- **Modo normal**: si hay `sha1sums` o `SKIP`, el script **descarga las fuentes**, calcula `sha256` y **reescribe** a `sha256sums` → vuelve a verificar.
- **STRICT=1**: **prohíbe** sumas débiles; no aplica autocorrección → **falla**.

### 4) Verificación PGP (si hay `.sig`)

- Si el `PKGBUILD` declara firmas `.sig`, **debe** pasar `makepkg --verifysource`.
- Si **no** hay `.sig`, se advierte (no se bloquea) — en `STRICT=1` el aviso es explícito.

### 5) `makepkg --verifysource`

- Se ejecuta **sin construir** (sólo integra/PGP).  
- Se omite cuando usas `--verify-only` (verificación estática), salvo que definas `DEEP=1`.  
- En `--fast`, se omite deliberadamente (revisión superficial con metadatos de `yay -Si`).

### 6) Resumen de `prepare()/build()/package()` (STRICT)

- Muestra las **primeras líneas** de cada función para visibilidad rápida antes de instalar.

### 7) Fijación de VCS (fuentes git+)

- Advierte cuando una fuente `git+https://…` no incluye `#commit=` o `#tag=`. En `STRICT=1`, esto hace que falle. Refuerza la reproducibilidad en paquetes VCS.

### 8) Resumen final (amigable para no expertos)

- Imprime un resumen claro (OK/ADVERTENCIA/FALLA/OMITIDO) con veredicto final y acción tomada.
- Localizado a español/inglés según la terminal.

<details>
<summary><strong>Campos del reporte y significado</strong></summary>

- Origen del PKGBUILD: de dónde se obtuvo (AUR snapshot/plain vs clon git de respaldo)
- Fijación de VCS: si las fuentes `git+…` están fijadas a `#commit=` o `#tag=`
- URLs de origen: valida que todas las fuentes usen HTTPS
- Dominios permitidos: valida contra una lista blanca
- Checksums: aplica y/o corrige política de sumas (sha256)
- Banderas rojas (diagnóstico): patrones sospechosos (solo VERBOSE/JS)
- makepkg --verifysource: verificación de integridad/PGP (omitido en verify‑only salvo `DEEP=1`)

Estados:

- OK: correcto
- ADVERTENCIA: potencial riesgo o práctica mejorable (no bloquea)
- FALLA: problema bloqueante; se aborta la instalación
- OMITIDO: omitido a propósito por el modo (verify‑only/fast)

Idioma:

- Auto: usa `LANG`/`LC_*` (español si comienza con `es`)
- Forzado: `REPORT_LANG=es` o `REPORT_LANG=en`

</details>

<details>
<summary><strong>Autodetección y obtención (Mermaid)</strong></summary>

```mermaid
%%{init: {"theme": "forest", "handDrawn": true}}%%
flowchart TD
    A[Entrada: URL AUR / URL GitHub / NombrePaquete]
    B{¿Tipo?}
    A --> B
    B -->|URL AUR| C[Extraer <nombre> de la URL]
    C --> H[Nombre de paquete]
    B -->|URL GitHub| D[Derivar candidatos desde README/título]
    D --> E[Validación estricta en AUR vía lib/search.sh]
    E --> H
    B -->|NombrePaquete| F{¿Coincidencia exacta en AUR RPC?}
    F -->|Sí| H
    F -->|No| G[Búsqueda estricta por nombre con yay -Ss <solo AUR>]
    G --> H

    H --> I{Obtener PKGBUILD}
    I -->|Plain OK| J[Snapshot/plain de AUR <sin git>]
    I -->|Plain falló| K[Clonado git superficial desde AUR]
    J --> L[Checks estáticos <reglas>]
    K --> L

    classDef ok fill:#e0ffe0,stroke:#9acd32,stroke-width:1px;
    classDef alt fill:#e6f0ff,stroke:#4f81bd,stroke-width:1px;
    classDef warn fill:#fff7cc,stroke:#ffc107,stroke-width:1px;
    class J ok;
    class K alt;
    class L warn;
```

</details>

---

## 🧩 Cómo decide instalar

- **Entrada = nombre de paquete AUR**  

  Obtiene `PKGBUILD` desde snapshot/plain de AUR (sin clonar), corre las verificaciones y, si todo pasa, instala con:

  ```bash
  yay -S --noconfirm <pkg>
  ```

- **Entrada = URL de GitHub (`https://github.com/OWNER/REPO`)**  

  Intenta mapear a un envoltorio AUR típico:
  - `owner-repo`
  - `owner-repo-bin`
  - `owner-repo-git`
  - y variantes detectadas

  Sólo acepta si el `PKGBUILD` realmente **apunta a ese repo** (comprobación del `source`/`url`).

- **`--fast`**  

  Afecta la profundidad de verificación (omite `makepkg --verifysource`) y sesga la resolución de nombre para preferir candidatos `-bin`/`-appimage` cuando aplique. No cambia el comando de instalación más allá de eso.

---

## 🔎 Detección de entrada (autodetección)

- **URL de paquete AUR** (`https://aur.archlinux.org/packages/<nombre>`): extrae `<nombre>` y obtiene desde snapshot/plain de AUR.
- **URL de GitHub**: deriva posibles envoltorios AUR (título del repo + nombre del repo, además de `-git`/`-bin`/`-appimage`) y valida contra AUR.
- **Nombre pelado**: consulta primero el AUR RPC v5 oficial para coincidencia exacta; si no existe, recurre a una búsqueda estricta por nombre en `yay -Ss` limitada a resultados de AUR.

Este enfoque minimiza la confianza en heurísticas locales y usa endpoints oficiales de AUR siempre que sea posible.

## 📚 Ejemplos

Verificar e instalar un cursor desde AUR (si existe):

```bash
sh ./bin/aur-verify oreo-nord-cursors-git
```

Sólo verificar sin instalar:

```bash
sh ./bin/aur-verify --verify-only oreo-nord-cursors-git
```

Verificar un envoltorio AUR partiendo de GitHub:

```bash
sh ./bin/aur-verify https://github.com/OWNER/REPO
```

Forzar modo estricto:

```bash
STRICT=1 sh ./bin/aur-verify <paquete>
```

Verificación superficial (sin descargas de `makepkg`):

```bash
FAST=1 sh ./bin/aur-verify <paquete>
```

---

## 🧠 Arquitectura

### Diseño modular

- `bin/aur-verify`: punto de entrada CLI que carga módulos y orquesta el flujo.
- Núcleo: `lib/core/shell_safety.sh` y `lib/utils/logging.sh`.
- Fetchers de AUR: `lib/aur/fetch_plain_and_snapshot.sh` (plain/snapshot; helpers RPC).
- Búsqueda/resolve AUR: `lib/aur/search_and_resolve.sh` (búsqueda estricta por nombre y resolvedor).
- Metadatos del repositorio: opcional vía `$YAY_BIN -Si` cuando esté disponible (sin archivo helper).
- Candidatos GitHub: `lib/github/derive_candidates_from_repo.sh` (parseo URL + título/README).
- Helpers PKGBUILD: `lib/pkgb/aggregate_pkgb_helpers.sh` (agrupa fuentes, checksums, redflags, resúmenes).
- Reglas de verificación: `lib/verify/rules.sh` (agrupa VCS pinning, fuentes, checksums, redflags, verifysource).
- Runner de verificación: `lib/verify/runner.sh` (orquesta verificación e instalación opcional).
- i18n: `lib/i18n/messages.sh` (en/es).
- Reporte: `lib/report/render_summary.sh` (resumen final localizado).
  (El wrapper legado `aur_verify_then_yay.sh` ha sido eliminado; usa `bin/aur-verify`.)

<details>
<summary><strong>Referencia de funciones (concisa)</strong></summary>

- Runner: `verify_pkgbuild`, `install_or_verify`, `aur_checkout_to`.
- Reglas: `rule_vcs_pinning`, `rule_sources`, `rule_checksums`, `rule_verifysource` (y `rule_red_flags` disponible; en el runner actual es diagnóstico).
- Helpers PKGBUILD: `list_sources`, `sources_have_only_https`, `sources_domains_allowed`, `has_strong_sums`, `has_weak_or_skip`, `rewrite_sums_to_sha256`, `scan_red_flags`, `print_func_summaries`, `pkgb_check_vcs_pinning`.
- AUR/GitHub + resolvedor: `aur_plain_fetch_*`, `aur_plain_rpc_*`, `resolve_pkg`, `aur_search_name_strict_aur_only`, `prefer_fast_variant`, `is_github_url`, `build_candidates_from_github`.

</details>

Mejoras recientes clave

- Parseo robusto del repo de GitHub con fallback seguro incluso en URLs atípicas.
- Búsqueda estricta por nombre en AUR basada en `yay -Ss`, filtrada a entradas `aur/...`.
- Listas de candidatos no vacías para evitar términos de búsqueda vacíos.

<details>
<summary><strong>Refactors para legibilidad y pruebas</strong></summary>

- La autodetección prefiere AUR snapshot/plain; el clonado git es solo respaldo.
- La verificación se dividió en reglas pequeñas y testeables en `lib/verify/rules.sh`.
- El reporte final y las traducciones viven en `lib/report/render_summary.sh` + `lib/i18n/messages.sh`.
- Es más fácil probar cada regla en aislamiento pasando un `PKGBUILD` y el modo.

</details>

<details>
<summary><strong>Vista general del flujo (Mermaid)</strong></summary>

```mermaid
%%{init: {"theme": "forest", "handDrawn": true}}%%
sequenceDiagram
    participant Usuario as Usuario
    participant CLI as CLI bin/aur-verify
    participant GitHub as GitHub lib/github/derive_candidates_from_repo.sh
    participant Search as Resolver AUR lib/aur/search_and_resolve.sh
    participant Plain as AUR Plain/RPC lib/aur/fetch_plain_and_snapshot.sh
    participant Verify as Verificador lib/verify/runner.sh
    participant Rules as Reglas lib/verify/rules.sh
    participant PKGB as PKGB Utils lib/pkgb/aggregate_pkgb_helpers.sh
    participant Report as Reporte lib/report/render_summary.sh + lib/i18n/messages.sh
    participant Makepkg as makepkg
    participant Yay as yay

    Usuario->>CLI: Ejecutar bin/aur-verify <input>

    %% Detección de entrada
    rect rgba(200, 200, 255, 0.35)
    CLI->>CLI: Detectar tipo de entrada
    alt URL AUR
        CLI->>Plain: Extraer nombre y consultar RPC v5
        Plain-->>CLI: pkg
    else URL GitHub
        CLI->>GitHub: Derivar candidatos titulo/README
        GitHub-->>CLI: Lista de candidatos
        CLI->>Search: Validar en AUR estricto por nombre
        Search-->>CLI: pkg
    else NombrePaquete
        CLI->>Plain: RPC v5 info busqueda exacta
        alt Existe exacto
            Plain-->>CLI: pkg
        else No exacto
            CLI->>Search: Busqueda estricta yay -Ss solo AUR
            Search-->>CLI: pkg
        end
    end
    end

    %% Obtención de PKGBUILD
    rect rgba(200, 255, 200, 0.35)
    CLI->>Verify: verify_pkgbuild pkg
    Verify->>Plain: Descargar snapshot/plain PKGBUILD y .SRCINFO
    alt Descarga OK
        Plain-->>Verify: Ruta temporal con PKGBUILD
    else Fallback a git
        Verify->>Plain: Intento fallido snapshot/plain
        Verify->>CLI: git clone desde AUR
        CLI-->>Verify: Repo clonado con PKGBUILD
    end
    Note over Verify: Mostrar resumen de funciones PREPARE / BUILD / PACKAGE
    end

    %% Verificación estática reglas atómicas
    rect rgba(255, 255, 200, 0.35)
    Verify->>Rules: rule_vcs_pinning PKGBUILD
    Rules->>PKGB: pkgb_check_vcs_pinning
    PKGB-->>Rules: Resultado
    Rules-->>Report: report_add item_vcs_pinning

    Verify->>Rules: rule_sources PKGBUILD
    Rules->>PKGB: list_sources + validaciones HTTPS y whitelist
    PKGB-->>Rules: Resultado
    Rules-->>Report: report_add item_source_urls / item_allowed_domains
    Note over Rules,Report: Por defecto → solo líneas problemáticas; Verbose → todas las fuentes con marca

    Verify->>Rules: rule_checksums PKGBUILD checkout
    Rules->>PKGB: has_weak_or_skip / has_strong_sums
    opt Autocorreccion permitida
        Rules->>Verify: rewrite_sums_to_sha256
    end
    Rules-->>Report: report_add item_checksums
    Note over Rules,Report: Por defecto → solo líneas débiles/SKIP; Verbose → arrays completas con marca

    Note over Verify: En --verbose, JS imprime líneas de banderas rojas (solo diagnóstico)
    end

    %% Verificación profunda opcional
    rect rgba(255, 220, 200, 0.35)
    alt VERIFY-ONLY sin DEEP
        Verify->>Rules: rule_verifysource mode verify-only
        Rules-->>Report: SKIP solo verificacion
    else FAST
        Verify->>Rules: rule_verifysource mode fast
        Rules-->>Report: SKIP --fast
    else FULL
        Verify->>Makepkg: makepkg --verifysource sin compilar
        Makepkg-->>Verify: OK / FALLO
        Verify->>Rules: rule_verifysource mode full
        Rules-->>Report: PASS / WARN / FAIL
    end
    end

    %% Reporte e instalación
    rect rgba(230, 200, 255, 0.35)
    Verify->>Report: report_print mode
    alt OVERALL OK u OK con advertencias y no verify-only
        CLI->>Yay: yay -S pkg
        Yay-->>CLI: Instalacion completada
    else OVERALL FAIL o verify-only
        CLI-->>Usuario: No instalar / Solo verificacion
    end
    Note over CLI,Report: Quiet → suprime info/warn; el resumen sigue visible
    end
```

</details>

<!-- Se eliminó sección duplicada de módulos clave para mantener DRY -->

<details>
<summary><strong>Detalles técnicos (para curiosos)</strong></summary>

- Reescritura de checksums: descarga fuentes declaradas, calcula `sha256` y reescribe `sha256sums=()` reemplazando sumas débiles (cuando se permite).  
- Resumen de funciones: imprime primeras líneas de `prepare()`, `build()`, `package()` para inspección rápida (con `STRICT=1`, salvo `--fast`).  
- Diagnóstico de errores: rutas y modos explícitos en “PKGBUILD not found …” y sugerencia accionable cuando `FAST=1` bloquea el fallback de plain.  
- Mensajes: prefijos `[INFO]`, `[WARN]`, `[ERROR]`; salida con código ≠ 0 ante fallos.

</details>

<details>
<summary><strong>Referencia de módulos (Bash y JS)</strong></summary>

Bash

- Núcleo y logging
  - `lib/core/shell_safety.sh`: opciones estrictas de Bash, `have_cmd`, `require_tools`.
  - `lib/utils/logging.sh`: `log_info`, `log_warn`, `log_error`, `die`.
- AUR y GitHub
  - `lib/aur/fetch_plain_and_snapshot.sh`: `aur_plain_fetch_plain_files`, `aur_plain_fetch_repo`, `aur_plain_rpc_*`.
  - `lib/aur/search_and_resolve.sh`: `resolve_pkg`, búsqueda estricta por nombre, resolvedor.
  - Metadatos del repositorio se leen oportunistamente vía `$YAY_BIN -Si` cuando esté presente.
  - `lib/github/derive_candidates_from_repo.sh`: parseo de URL, scraping de README/título, candidatos.
- PKGBUILD helpers
  - `lib/pkgb/sources_and_domains.sh`: `list_sources`, validaciones HTTPS/domains.
  - `lib/pkgb/checksums_policy.sh`: `has_strong_sums`, `has_weak_or_skip`, `rewrite_sums_to_sha256`.
  - `lib/pkgb/redflags_scan.sh`: `scan_red_flags` con lista compartida.
  - `lib/pkgb/functions_summary.sh`: `print_func_summaries`.
  - `lib/pkgb/aggregate_pkgb_helpers.sh`: agrega todo lo anterior y `pkgb_check_vcs_pinning`.
- Verificación
  - `lib/verify/rules.sh`: agrega reglas de `lib/verify/rules/*.sh`.
  - Reglas: `vcs_pinning_rule.sh`, `sources_rule.sh`, `checksums_rule.sh`, `redflags_rule.sh`, `verifysource_rule.sh`.
  - `lib/verify/runner.sh`: `verify_pkgbuild`, `install_or_verify`, `aur_checkout_to`.
- i18n y Reporte
  - `lib/i18n/messages.sh`: traducciones (en/es).
  - `lib/report/render_summary.sh`: resumen final localizado.

JavaScript (Node)

- Composición del parser: `lib/pkgb/parser/parser/composePkgbuildParser.js` (exporta `parsePKGBUILD`).
- Spider/crawler: `lib/pkgb/parser/parser/spider/{crawlPkgbuildAndEmitHooks,scanBalancedParentheses,scanBalancedCurlyBraces}.js`.
- Ayudantes: `lib/pkgb/parser/parser/{extractPkgbuildArraysAndMapFields,extractScalarsToMetaAndChecksums,analyzeSourcesResolvePinsAndDomains,computeRiskScoresAndSeverity}.js`.
- Patrones: `lib/pkgb/parser/patterns/{compileRegexPatterns.js,modules/loadSharedRedflags.js}`.
- Salidas: `lib/pkgb/parser/outputs/modules/{renderDetailedAnalysis,renderSummaryLine,renderSignalsKeyValue,renderRedflagsLines,renderCompactSources}.js`.
- Utils: `lib/pkgb/parser/utils/modules/{parseShellStyleTokensAndStripComments,networkFetch,stdinRead}.js`.
- Colores: `lib/pkgb/parser/terminalColors.js`. Façade: `lib/pkgb/parser/analysis.js`.

</details>

## 🔐 Notas de seguridad

- Este script **no construye** el paquete durante la verificación (usa `makepkg --verifysource`).  
- **No** elude las políticas de AUR: simplemente automatiza controles habituales (y añade reglas más estrictas si lo pides).
- `--fast` está pensado para **revisión superficial**; úsalo sólo si confías en el paquete/maintainer.
- La lista blanca de dominios y las banderas rojas son **opinadas**; puedes ajustarlas en el script si lo necesitas.

---

## 🛠️ Solución de problemas

- **“AUR clone failed (package may not exist)”**  

  Revisa el nombre del paquete o si realmente existe en AUR.
- **“sha256 verification failed after regeneration”**  

  El upstream cambió o hay un vector de ataque; no instales hasta entender la causa.
- **“source domain not allowed” (STRICT)**  

  Añade el dominio a la lista blanca en el script o instala en modo normal (bajo tu criterio).
- **“Plain PKGBUILD unavailable for '<pkg>' while FAST=1”**  
  
  El modo FAST deshabilita los fallbacks de snapshot/git. Ejecuta sin `--fast` para permitir snapshot/git, o prueba una variante `-bin`/`-appimage`.
\- **“PKGBUILD not found at '<path>/PKGBUILD' (mode=..., pkg=...)”**  
  Ejecuta sin `--fast` para permitir el fallback a snapshot/git. Si aún falla, abre un issue incluyendo la ruta mostrada.

---

## 🧪 Comandos de ejemplo (copiar/pegar)

```bash
# Verificar e instalar (normal)
sh ./bin/aur-verify <paquete>

# Verificar solamente
sh ./bin/aur-verify --verify-only <paquete>

# Modo estricto (dominios whitelisted, sin sumas débiles, PGP cuando haya .sig)
STRICT=1 sh ./bin/aur-verify <paquete>

# Verificación rápida basada en metadatos
FAST=1 sh ./bin/aur-verify <paquete>

# Desde GitHub: localizar el envoltorio AUR y verificar/instalar
sh ./bin/aur-verify https://github.com/OWNER/REPO
```

---

## 📄 Licencia

Este proyecto está licenciado bajo MIT. Ver [LICENSE](LICENSE).

---

### Créditos

Mantenido por las personas colaboradoras del proyecto. Consulta [AUTHORS](AUTHORS) para créditos y agradecimientos.
