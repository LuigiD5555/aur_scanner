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

1) **Clona** el repositorio de AUR (o **detecta** el paquete AUR que envuelve una URL de GitHub).  
2) **Audita** el `PKGBUILD` con controles estáticos (banderas rojas comunes).  
3) **Verifica la integridad** de las fuentes con `makepkg --verifysource`.  
4) **Corrige** sumas débiles (p. ej. `sha1sums`/`SKIP`) reemplazándolas por `sha256sums` (sólo en modo normal).  
5) **(Opcional)** **Refuerza** la política en **modo estricto**: dominios permitidos, sin sumas débiles, y verificación PGP cuando hay `.sig`.  
6) Si todo está limpio, **instala** automáticamente con `yay -S` (salvo que uses `--verify-only`).

> Pensado para quienes no confían a ciegas en AUR: valida primero, instala después.

---

## 🚀 Uso rápido

Puedes ejecutarlo mediante el wrapper legado o el nuevo punto de entrada modular:

- Wrapper (compatibilidad hacia atrás):
  - `sh ./aur_verify_then_yay.sh <paquete|URL_de_GitHub>`
- Punto de entrada modular:
  - `bash bin/aur-verify <paquete|URL_de_GitHub>`

Instalar tras verificar un paquete AUR:

```bash
sh ./aur_verify_then_yay.sh oreo-nord-cursors-git
```

Sólo verificar (no instalar):

```bash
sh ./aur_verify_then_yay.sh --verify-only oreo-nord-cursors-git
```

Modo estricto (políticas más duras):

```bash
STRICT=1 sh ./aur_verify_then_yay.sh oreo-nord-cursors-git
```

Verificación rápida (metadatos, sin descargas de `makepkg`):

```bash
FAST=1 sh ./aur_verify_then_yay.sh <paquete-AUR>
```

Detectar y verificar a partir de un repositorio GitHub (busca el envoltorio AUR):

```bash
sh ./aur_verify_then_yay.sh https://github.com/OWNER/REPO
```

---

## 📦 Requisitos

- Arch Linux o derivado con acceso a AUR.
- Herramientas: `git`, `curl`, `makepkg` (parte de `pacman`), y un ayudante AUR compatible: `yay` (por defecto).  
  - Puedes cambiar el binario de yay con `YAY_BIN=/ruta/a/yay`.

```bash
# Dar permisos de ejecución
chmod +x ./aur_verify_then_yay.sh
```

---

## 🔧 Opciones y variables

**Flags**:

- `--verify-only` — Ejecuta las verificaciones y **sale sin instalar**.
- `--fast` — Verificaciones **sólo de metadatos** (omite `makepkg --verifysource`). ⚠️ En `STRICT=1` reduce garantías.
- `-h`/`--help` — Ayuda.

**Variables de entorno**:

- `STRICT=1` — Activa **modo estricto**:
  - **Prohíbe** `sha1`, `SKIP` o ausencia de sumas fuertes.
  - **Lista blanca de dominios** (por defecto): `github.com`, `codeload.github.com`, `objects.githubusercontent.com`, `gitlab.com`.
  - Si hay archivos `.sig` en `source=()`, **debe** pasar `makepkg --verifysource` (PGP).
  - Muestra un **resumen** de funciones `prepare()`, `build()`, `package()`.
- `YAY_BIN=/ruta/yay` — Cambia el binario de yay.

---

## ✅ Qué comprueba

### 1) Banderas rojas en `PKGBUILD` (estático)

Busca patrones peligrosos o poco confiables, por ejemplo:

- **Descargas autoejecutadas**: `curl|wget ... (sh|bash)`
- **Sockets TCP en shell**: `/dev/tcp`
- **Ejecución dinámica**: `eval`, `$(...)`, `` `...` ``, `exec(`
- **Decodificación/descifrado** en línea: `base64 -d`, `openssl enc -d`
- **Privilegios/permiso sospechoso**: `chmod +s`, `setcap`, escritura sobre `/etc`
- **Trampas en rutas**: uso indebido de `pkgdir` apuntando a `/etc`
- **(STRICT)** one-liners con `python -c`, `perl -e`, `ruby -e`, `node -e`

> Si detecta algo, **falla** con explicación.

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
- En `--fast`, se omite deliberadamente (revisión superficial con metadatos de `yay -Si`).

### 6) Resumen de `prepare()/build()/package()` (STRICT)

- Muestra las **primeras líneas** de cada función para visibilidad rápida antes de instalar.

---

## 🧩 Cómo decide instalar

- **Entrada = nombre de paquete AUR**  

  Clona `https://aur.archlinux.org/<pkg>.git`, corre las verificaciones y, si todo pasa, instala con:

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

  Si el paquete **está** en repos oficiales: lo instala directamente (sin construir).  

  Si **es AUR** y **requiere compilación**, intenta **alternar** a un sabor rápido (p. ej. `*-bin`). Si no hay, **falla** (para evitar builds largos).

---

## 📚 Ejemplos

Verificar e instalar un cursor desde AUR (si existe):

```bash
sh ./aur_verify_then_yay.sh oreo-nord-cursors-git
```

Sólo verificar sin instalar:

```bash
sh ./aur_verify_then_yay.sh --verify-only oreo-nord-cursors-git
```

Verificar un envoltorio AUR partiendo de GitHub:

```bash
sh ./aur_verify_then_yay.sh https://github.com/OWNER/REPO
```

Forzar modo estricto:

```bash
STRICT=1 sh ./aur_verify_then_yay.sh <paquete>
```

Verificación superficial (sin descargas de `makepkg`):

```bash
FAST=1 sh ./aur_verify_then_yay.sh <paquete>
```

---

## 🧠 Arquitectura

### Diseño modular

- `bin/aur-verify`: punto de entrada CLI que carga módulos y orquesta el flujo.
- `lib/common.sh`: seguridad de shell, re‑ejecución en bash, comprobación de herramientas.
- `lib/log.sh`: helpers de logging estructurado.
- `lib/yay.sh`: extracción de metadatos con `yay -Si`, detección de repositorio.
- `lib/github.sh`: parseo de URLs de GitHub, lectura de README/título, fallback robusto del repo.
- `lib/search.sh`: generación de candidatos, búsqueda estricta en AUR sobre `yay -Ss`, resolvedor.
- `lib/pkgb.sh`: parsers de PKGBUILD, políticas de dominios/checksums, escaneo de banderas rojas.
- `lib/verify.sh`: clonado, verificación con makepkg, reescritura de sums opcional, instalación.
- `aur_verify_then_yay.sh`: wrapper legado que delega a `bin/aur-verify`.

Mejoras recientes clave

- Parseo robusto del repo de GitHub con fallback seguro incluso en URLs atípicas.
- Búsqueda estricta por nombre en AUR basada en `yay -Ss`, filtrada a entradas `aur/...`.
- Listas de candidatos no vacías para evitar términos de búsqueda vacíos.

<details>
<summary><strong>Vista general del flujo</strong></summary>

```text
[Entrada: paquete o URL GitHub]
        │
        ▼
   Temp dir (mktemp)
        │
        ├─ Si es URL de GitHub → heurística para encontrar el paquete AUR (owner-repo, -bin, -git...)
        │        │
        │        └─ Verifica que el PKGBUILD apunte a ese repo
        │
        ├─ Clona AUR: https://aur.archlinux.org/<pkg>.git
        │
        ├─ Escaneo estático de PKGBUILD (banderas rojas)
        │
        ├─ Validación de dominios en source=()
        │
        ├─ makepkg --verifysource
        │        └─ Si falla por sumas débiles (y STRICT=0): auto-regenera sha256sums
        │
        ├─ (STRICT) Resumen prepare/build/package
        │
        ├─ --verify-only ? → salir con código 0
        │
        └─ Instala con yay -S --noconfirm
```

</details>

<details>
<summary><strong>Módulos clave (alto nivel)</strong></summary>

- **`lib/github.sh`**: parseo de URL, título de README, candidatos en kebab-case, fallback seguro de repo.
- **`lib/search.sh`**: búsqueda estricta basada en `yay -Ss`, filtrada a AUR, orden de candidatos, resolvedor.
- **`lib/pkgb.sh`**: análisis de `source`, políticas de checksums, resúmenes de funciones, banderas rojas.
- **`lib/verify.sh`**: clonado, verificación con makepkg, reescritura opcional de checksums, ruta de instalación.
- **`lib/yay.sh`**: extracción de campos de `yay -Si`, metadatos de repositorio/origen.

</details>

<details>
<summary><strong>Detalles técnicos (para curiosos)</strong></summary>

- **Reescritura de checksums**: descarga fuentes declaradas, calcula `sha256` y genera un bloque `sha256sums=()` en `PKGBUILD` reemplazando `sha1sums` o entradas `SKIP`.

### Detalles técnicos (para curiosos)

- **Reescritura de checksums**: descarga fuentes declaradas, calcula `sha256` y genera un bloque `sha256sums=()` en `PKGBUILD` reemplazando `sha1sums` o entradas `SKIP`.
- **Resumen de funciones**: imprime las primeras líneas de `prepare()`, `build()`, `package()` para inspección rápida antes de instalar (sólo con `STRICT=1` y sin `--fast`).
- **Mensajes**: prefijos `[INFO]`, `[WARN]`, `[ERROR]` para claridad en logs.
- **Salida**: cualquier fallo detiene el proceso con código ≠ 0.

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
- **“FAST: would require a full AUR build”**  

  Intenta un sabor `-bin` o ejecuta sin `--fast` (aceptando compilar).

---

## 🧪 Comandos de ejemplo (copiar/pegar)

```bash
# Verificar e instalar (normal)
sh ./aur_verify_then_yay.sh <paquete>

# Verificar solamente
sh ./aur_verify_then_yay.sh --verify-only <paquete>

# Modo estricto (dominios whitelisted, sin sumas débiles, PGP cuando haya .sig)
STRICT=1 sh ./aur_verify_then_yay.sh <paquete>

# Verificación rápida basada en metadatos
FAST=1 sh ./aur_verify_then_yay.sh <paquete>

# Desde GitHub: localizar el envoltorio AUR y verificar/instalar
sh ./aur_verify_then_yay.sh https://github.com/OWNER/REPO
```

---

## 📄 Licencia

Este proyecto está licenciado bajo MIT. Ver [LICENSE](LICENSE).

---

### Créditos

Mantenido por las personas colaboradoras del proyecto. Consulta [AUTHORS](AUTHORS) para créditos y agradecimientos.
