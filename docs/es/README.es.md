# AUR Scanner (Bash)

> **Verifica primero, instala después** — Verificador de seguridad para paquetes AUR (y wrappers de GitHub) con instalación automática vía `yay` solo si todo pasa.

[![Bash](https://img.shields.io/badge/Bash-4EAA25?logo=gnu-bash&logoColor=white)](https://www.gnu.org/software/bash/)
[![Arch Linux](https://img.shields.io/badge/Arch_Linux-1793D1?logo=archlinux&logoColor=white)](https://archlinux.org/)
[![AUR](https://img.shields.io/badge/AUR-1793D1?logo=archlinux&logoColor=white)](https://aur.archlinux.org/)
[![makepkg --verifysource](https://img.shields.io/badge/makepkg--verifysource-enabled-blue)](https://wiki.archlinux.org/title/Makepkg)
[![PGP](https://img.shields.io/badge/PGP-verification-informational?logo=gnupg&logoColor=white)](https://gnupg.org/)
[![sha256](https://img.shields.io/badge/checksums-sha256-success)](https://en.wikipedia.org/wiki/SHA-2)
[![yay](https://img.shields.io/badge/helper-yay-0A0A0A)](https://github.com/Jguer/yay)
[![Ko-fi](https://img.shields.io/badge/Ko--fi-Buy%20me%20a%20coffee-FF5E5B?logo=kofi&logoColor=white)](https://ko-fi.com/luigid5555)

---

🌐 Read this in [English](../../README.md)

---

## 📚 Documentación

- Documentación para desarrolladores (rama development): [English](https://github.com/LuigiD5555/aur_scanner/blob/development/docs/developer/README.dev.md) | [Español](https://github.com/LuigiD5555/aur_scanner/blob/development/docs/developer/README.dev.es.md)

---

## 🧭 ¿Qué hace esta herramienta?

Esta herramienta toma un nombre de paquete de AUR **o** una URL de GitHub y:

- Descarga el PKGBUILD desde AUR (plain → snapshot → git superficial como último recurso).
- Audita banderas rojas estáticas, uso de HTTPS/dominios permitidos y políticas de sumas de verificación.
- Verifica fuentes con `makepkg --verifysource` (cuando aplica).
- **Modo estricto** endurece las políticas (sin sumas débiles, solo dominios permitidos, PGP cuando existe `.sig`).
- Si todo está limpio, instala con `yay -S` (a menos que uses `--verify-only`).

> Diseñado para quienes no confían ciegamente en AUR: valida primero, instala después.

---

## ✅ Qué verifica

### 1) Banderas rojas en `PKGBUILD` (escaneo estático)

Primero intenta con señales del parser en JS (`bin/pkgb-parse`); si no está disponible, recurre a heurísticas en Bash usando reglas en `lib/rules/redflags.list`. Busca patrones como:

- **Descargas autoejecutables**: `curl|wget ... | (sh|bash)`
- **Ejecución dinámica**: `eval`, `bash -c`, sustitución de comandos `$()`
- **Decodificación/cifrado en línea**: `base64 -d`, `openssl enc`
- **Sockets crudos en shell**: `/dev/tcp/`
- **Eliminaciones peligrosas**: `rm -rf /`, `$*`
- **Abuso de privilegios/permisos**: `chmod 4xxx/7xxx`, `setcap`, `systemctl (enable|start)`, `useradd`
- **One-liners**: `python -c`, `perl -e`, `ruby -e`, `node -e`

**Resultado:**

- Con **parser JS**: si `redFlags>0` → `WARN` (o `FAIL` en `STRICT=1`).
- Con **Bash**: igual, pero solo heurísticas por regex.

---

### 2) Dominios y HTTPS en `source=()`

- **Enforzamiento de HTTPS**: marca cualquier fuente que no use HTTPS.
- **Lista blanca de dominios** (por defecto, configurable con `ALLOWED_DOMAINS`):
  `github.com | codeload.github.com | objects.githubusercontent.com | gitlab.com`

**Resultado:**

- No HTTPS → `WARN` (o `FAIL` en `STRICT=1`).
- Fuera de la lista → `WARN` (o `FAIL` en `STRICT=1`).

---

### 3) Fijación de VCS en `git+…`

Requiere `#commit=` o `#tag=` en las fuentes `git+…`. De lo contrario se marca como **no fijado**.

**Resultado:**

- Sin pin → `WARN` (o `FAIL` en `STRICT=1`).
- Correctamente fijado → `PASS`.

---

### 4) Política de checksums

- Detecta sumas débiles (`md5sums`, `sha1sums`) o **`SKIP`**.
- Si faltan sumas fuertes (`sha256sums` / `sha512sums`), intenta corregir.
- En modo normal (no `--fast` / `--verify-only`), trata de **regenerar automáticamente** `sha256sums` con `makepkg -g`.

**Resultado:**

- **`STRICT=1`**: cualquier suma débil/`SKIP`/falta de suma fuerte → `FAIL` (sin autocorrección).
- **Normal**:
  - `--fast` o `--verify-only` → `WARN` (salta regeneración).
  - Completo: si reescribir a `sha256sums` funciona → `PASS`; de lo contrario `WARN`.

---

### 5) `makepkg --verifysource` (incluye PGP si existe)

Ejecuta `makepkg --verifysource` **sin compilar** (descargas/PGP/checksums) solo en **modo completo**.

**Resultado:**

- **Completo (por defecto)**:
  - Éxito → `PASS`.
  - Falla → `WARN` (o `FAIL` en `STRICT=1`).
- **`--fast`** → omitido.
- **`--verify-only`** (sin `DEEP=1`) → omitido.

> Si el `PKGBUILD` incluye archivos `.sig`, la verificación PGP ocurre dentro de `--verifysource`.
> Si no, nada falla por firmas ausentes, aunque otros chequeos pueden advertir.

---

### 6) Resumen de funciones (`prepare()/build()/package()`)

Si `SHOW_FUNCS=1`, imprime un **resumen textual** de los cuerpos de función (no los ejecuta) para dar visibilidad rápida antes de instalar.

**Resultado:** Solo informativo (sin PASS/WARN/FAIL).

---

### 7) Señales del parser JS (si Node + `bin/pkgb-parse`)

Integra 3 contadores de señales:

- `unpinnedGit`, `nonHttps`, `redFlags`

Aparecen en el reporte como `item_js_unpinned`, `item_js_https`, `item_js_redflags` con severidad **WARN** (subido a **FAIL** en `STRICT=1`).

---

## 🧩 Otros chequeos / metadatos

- **Origen del PKGBUILD**: `plain` | `snapshot` | `git`, más si **plain** estaba disponible (puede ser `PASS/WARN/FAIL` según `STRICT`).
- **Modo efectivo**: `full`, `fast`, `verify-only` (controla `--verifysource`).
- **Integración con wrapper** (`scan`): aborta instalación del helper si la verificación da **FAIL** y, en actualizaciones (`yay -Syu` / `paru -Syu`), omite automáticamente los paquetes problemáticos usando `--ignore`.
- **Corte temprano:** las revisiones estáticas corren antes de descargar fuentes; si fallan, se omiten pasos pesados (por ejemplo `makepkg --verifysource`).

---

## 🚀 Inicio rápido

### Instalar desde AUR (beta)

```bash
yay -S aur-scanner-git
```

- Instala los archivos del wrapper en `/usr/lib/aur-scanner`.
- El paquete está marcado como **beta**; la API y CLI aún pueden cambiar.

### Wrapper drop-in (transparente)

Tras instalar, envuelve tu helper de AUR de manera transparente:

```bash
yay -Syu <aur-package>
paru -S <aur-package>
pamac build <aur-package>
```

- Si la verificación falla en una instalación puntual, se bloquea al helper.
- En actualizaciones completas (`yay -Syu`, `paru -Syu`, `pikaur -Syu`, etc.) escanea la cola AUR y añade las fallidas a `--ignore` para que el resto continúe.
- Si todo pasa, tu helper sigue normalmente.
- Para omitir una vez, puedes poner: `SCAN_BYPASS=1` (no recomendado).
- Banderas como `--verify-only`, `--strict` o `--fast` solo se reconocen **cuando el nombre del helper apunta al wrapper**. Para instalaciones manuales crea tú mismo el enlace simbólico (`ln -sf /ruta/al/repo/bin/scan ~/.local/bin/yay`).
- Para chequeos del parser sin descargas, ejecuta mediante el wrapper con `FAST=1 --verify-only` (o `FAST=1 VERIFY_ONLY=1`).
- Los shims de helper detectan automáticamente las banderas del wrapper: si escribes `yay … --verify-only`, el shim entrega el control a `scan`; de lo contrario delega directo al helper real.
- ¿No sabes en qué modo estás? Ejecuta `command -v yay` y luego `readlink -f "$(command -v yay)"`. Si ambos apuntan al wrapper (`…/scan`), puedes usar `yay -Syu pkg --verify-only`; si muestran `/usr/bin/yay`, llama explícitamente `scan yay -Syu --verify-only pkg` (o crea el shim).

> **Nota:** pacman no instala paquetes AUR; se deja intacto.
>
> Toda la configuración de bajo nivel la maneja la app. Detalles de integración avanzada están en la documentación de desarrollo.

### ⌨️ CLI directo (opcional para usuarios avanzados)

También puedes llamar al verificador directamente para mayor control:

```bash
aur-scanner <paquete>
aur-scanner --verify-only <paquete>
aur-scanner --strict <paquete>
aur-scanner --fast <paquete>
aur-scanner https://github.com/OWNER/REPO
```

---

## 🔧 Opciones principales

Cada opción puede usarse **ya sea como bandera** o como **variable de entorno**:

| Modo              | Banderas           | Variables entorno      |
| ----------------- | ------------------ | ---------------------- |
| Verify only       | `--verify-only`    | `VERIFY_ONLY=1`        |
| Fast check        | `--fast`           | `FAST=1`               |
| Strict policies   | `--strict`         | `STRICT=1`             |
| Verbose logging   | `--verbose`        | `VERBOSE=1`            |
| Quiet logging     | `--quiet`          | `QUIET=1`              |

> Ejemplo: tanto `aur-scanner --strict pkg` como `STRICT=1 aur-scanner pkg` hacen lo mismo.

---

## 🧩 Escenarios de uso

Esta herramienta se adapta a distintas necesidades. Casos prácticos:

### ✅ Modo normal (por defecto)

```bash
aur-scanner <aur-package>
```

- Para instalaciones diarias de **paquetes AUR conocidos**.
- Equilibrio entre seguridad y velocidad.
- Corrige automáticamente sumas débiles, advierte pero no bloquea problemas menores.

### 🛡️ Modo estricto

```bash
aur-scanner --strict <aur-package>
```

- Para **entornos sensibles a la seguridad** o **paquetes desconocidos**.
- Solo HTTPS de dominios permitidos.
- No se permiten sumas débiles/omitidas.
- Requiere archivos `.sig` válidos.

### ⚡ Modo rápido

```bash
aur-scanner --fast <aur-package>
```

- Para **vistazos rápidos** sin descargas.
- Útil con bajo ancho de banda o al revisar paquetes.
- Superficial — úsalo con precaución.

### 🔍 Solo verificar

```bash
aur-scanner --verify-only <aur-package>
```

- Para **auditar paquetes sin instalarlos**.
- Ideal en pipelines CI/CD.
- Agrega `DEEP=1` para revisiones completas de fuentes + PGP.

### Resumen de uso

| Modo      | Seguridad | Velocidad  |          Descargas          |                Caso de uso                 |
| --------- | --------- | ---------- | --------------------------- | ------------------------------------------ |
| Normal    | Media     | Rápida     | Sí                          | Instalaciones diarias de AUR comunes       |
| Estricto  | Alta      | Más lenta  | Sí                          | Paquetes desconocidos / sistemas sensibles |
| Rápido    | Baja      | Muy rápida | No                          | Vista rápida, metadatos                    |
| Verificar | Alta      | Variable   | No (def.) / Sí (con DEEP=1) | Solo auditoría, CI/CD                      |

### 🔀 Ejemplos de flujo

- **Paquete desconocido:** `STRICT=1 aur-scanner my-unknown-pkg`
- **Actualización diaria (wrapper yay):** `yay -Syu` (omite automáticamente las actualizaciones AUR con fallos)
- **Vista rápida navegando AUR:** `aur-scanner --fast --verify-only <package-name>`
- **Auditoría en pipeline:** `DEEP=1 aur-scanner --verify-only custom-helper-git`

---

## 🧠 Anatomía del script (estado actual)

<details>
<summary><strong>Flujo de alto nivel (bin/aur-verify)</strong></summary>
```plaintext
[Entrada: nombre de paquete AUR | URL AUR | URL GitHub]
        │
        ├─ Procesar flags/env:
        │     --verify-only, --fast, --strict, --verbose, --quiet, --metadata
        │
        ▼
   Resolver paquete AUR
        │
        ├─ Si es URL GitHub → derive_candidates_from_repo (README/título → kebab-case)
        │        │
        │        └─ AUR RPC (cache / en vivo) + búsqueda estricta (fallback: yay -Ss)
        │
        └─ Si es URL AUR → tomar slug final; si es token simple → normalizar & probar variantes
                  (-git, -bin, -appimage; FAST prefiere “no -bin” primero)
        │
        ▼
   Checkout de PKGBUILD
        │
        ├─ Intento 1: AUR plain (PKGBUILD directo; cachea .json del LLPR/RPC)
        │
        ├─ Si falla y no --fast:
        │        ├─ Intento 2: snapshot .tar.gz
        │        └─ Intento 3: git clone (fallback)
        │
        └─ (Verbose/Strict) también puede traer .SRCINFO
        │
        ▼
   Reporte: fuente del PKGBUILD
        ├─ plain | snapshot | git + “plain disponible/no disponible”
        └─ (Verbose) resumen de prepare()/build()/package()
        │
        ▼
   Señales JS (si Node + bin/pkgb-parse)
        ├─ unpinnedGit / nonHttps / redFlags → export counters
        └─ (Verbose) muestra resumen, fuentes compactas, líneas marcadas
        │
        ▼
   Reglas de verificación (Bash + señales JS)
        ├─ Pin SCV (git+… requiere #commit= o #tag=) → PASS/WARN/FAIL (STRICT)
        ├─ Solo HTTPS + lista de dominios (ALLOWED_DOMAINS por defecto: GitHub/GitLab/…)
        ├─ Checksums:
        │     • Si md5/sha1 o SKIP:
        │         - STRICT: FAIL
        │         - --fast: WARN
        │         - --verify-only: WARN
        │         - Normal: regenerar sha256sums (makepkg -g) → PASS/WARN
        ├─ Red flags (vía JS si disponible; fallback grep)
        └─ makepkg --verifysource (modo depende):
              • completo (def.) → ejecutar
              • rápido / solo verificar → SKIP
              • STRICT sube algunos WARN a FAIL
        │
        ▼
   Resumen (i18n en/es): PASS/WARN/FAIL + “OK | OK (con advertencias) | FAIL”
        │
        ├─ --verify-only → salir con código según resultado
        └─ (La instalación NO es automática aquí)
```
</details> 

> **SCV:** Sistema de Control de Versiones
> **LLPR:** Llamada a Procedimiento Remoto (RPC)

<details>
<summary><strong>Integración con wrapper (bin/scan)</strong></summary>

```plaintext
[Invocación: scan <helper> <args>]
        │
        ├─ Detecta helper real (yay/paru/pikaur/trizen/pamac)
        ├─ Extrae paquetes candidatos (pacman -S/-U o pamac build/install/upgrade)
        ├─ Ejecuta: bin/aur-verify --verify-only -- <candidates>
        │       └─ Si verificación FALLA → aborta (exit 2)
        │
        └─ Si verificación OK (o no hay AUR) → delega al helper real (exec)
```
</details>

### Notas rápidas (comportamiento actual)

- **Descarga**: siempre prefiere **AUR plain**; si falla y no `--fast`, cae a **snapshot** y luego **git clone**.
- **Resolución**: usa **AUR RPC v5** con cache ligero en `/tmp`, coincidencia estricta de nombres y, como último recurso, `yay -Ss`. Para GitHub, deriva candidatos de README/título y normaliza con *kebab-case* + variantes (`-git/-bin/-appimage`).
- **Señales JS opcionales**: si existen Node y `bin/pkgb-parse`, agrega señales (unpinnedGit/nonHttps/redFlags) y muestra detalles en `--verbose`.
- **Checksums**: si encuentra **md5/sha1/SKIP**, en modo normal intenta **reemplazar automáticamente** por `sha256sums` (salvo en `--verify-only` o `--fast`); `--strict` los trata como **FAIL**.
- **HTTPS + dominios**: requiere HTTPS y valida contra `ALLOWED_DOMAINS` (configurable por env).
- **Pin de VCS**: requiere `#commit=` o `#tag=` en fuentes `git+…` (WARN/FAIL según `--strict`).
- **makepkg --verifysource**: corre solo en **modo completo**; omitido en `--fast` o `--verify-only`.
- **Reportes**: internacionalizado (en/es) con banners “BEGIN/END”, totales PASS/WARN/FAIL y acción sugerida.

---

## 🧪 Qué verifica (resumen)

- **Pin de SCV**: `git+https://…` debe usar `#commit=` o `#tag=` (estricto = requerido).
- **URLs de fuente**: exige HTTPS y valida contra lista permitida (estricto).
- **Checksums**: preferir `sha256sums`; débiles/`SKIP` son rechazados o reescritos (no estricto).
- **PGP**: si se declara `.sig`, `makepkg --verifysource` debe pasar.
- **Banderas rojas**: resalta patrones riesgosos (diagnóstico).

> Ver reglas completas y tabla de severidad en la [documentación de desarrollo](../developer/README.dev.es.md).

---

## 🛡️ Notas de seguridad

- El verificador **no compila** paquetes; revisiones profundas dependen de `makepkg --verifysource`.
- `--fast` es **superficial**; para sistemas sensibles usar estricto+profundo.
- Lista blanca y reglas de banderas rojas son personalizables.

---

## ❓ Solución de problemas

- **“Package may not exist”** → confirma el nombre en AUR.
- **“sha256 verification failed”** → el upstream cambió; no instales hasta entender por qué.
- **“Plain PKGBUILD unavailable while FAST=1”** → reejecuta sin `--fast`.

Más escenarios y logs: ver docs de desarrollo.

---

## 🤝 Contribuciones

Se aceptan contribuciones — código, docs, tests y propuestas de reglas.
Buenas primeras tareas: mejoras de documentación, mensajes de error más claros, tests adicionales.
Ver docs de desarrollo para arquitectura, reglas y entorno de pruebas.

---

## ☕ Apoya el proyecto

Si esta herramienta te ahorra tiempo o hace tu flujo en Arch más seguro, considera apoyar:

[![Support on Ko-fi](https://img.shields.io/badge/Ko--fi-Support%20the%20project-FF5E5B?logo=kofi&logoColor=white)](https://ko-fi.com/luigid5555)

Tu apoyo mantiene las reglas al día, mejora docs y hace sostenibles las pruebas. ¡Muchas Gracias!

---

## Licencia

Este proyecto está bajo la Licencia MIT. Ver [LICENSE](../../LICENSE) para más detalles.

### Créditos

Mantenido por los contribuidores del proyecto. Ver [AUTHORS](../../AUTHORS) para créditos y agradecimientos.
