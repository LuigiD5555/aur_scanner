# 📜 Changelog

Todos los cambios relevantes de este proyecto se documentarán en este archivo.  
El formato está basado en Keep a Changelog,  
y este proyecto sigue Semantic Versioning.

---

## [Sin publicar]

- Trabajo en progreso hacia la versión **1.0.0 estable**.

---

## [0.8.0] - 2025-09-26

### Añadido

- **Matriz de Comportamiento** bajo Runtime para clarificar la precedencia de flags/modos.
- Subsección **Lista de Dominios Permitidos** bajo Reglas de Verificación → Fuentes.
- Subsección **Modelo de Amenazas** bajo Modelo de Seguridad.
- Notas de seguridad explícitas:
	- reescritura automática de checksums (`makepkg -g`) solo en modos relajados.
	- `makepkg --verifysource` se ejecuta como usuario sin privilegios con `umask 077`.
- Advertencias para toggles de debug (`SCAN_BYPASS`, `SCAN_REAL_YAY`).

### Cambiado

- Sección de **Contribuciones**:
	- Énfasis en el setup de desarrollo local.
	- Se añadieron tres métodos de setup para desarrollo (ejecución directa, script de instalación, `makepkg`).
- **Tabla de Contenidos** corregida a anchors correctos de GitHub.
- Separación clara entre instalación para usuarios finales (paquete AUR) vs setup para desarrolladores.
- Mejoras de consistencia en la redacción (intro de Contribuciones, Guías).

---

## [0.7.0] - 2025-09-04

### Añadido

- Soporte para fallback `tree?plain=1` al obtener PKGBUILD.
- Parser Node extendido con output `--signals`.

### Cambiado

- Reportes i18n mejorados (cobertura en español).
- Receta de CI actualizada para correr con `STRICT=1 VERIFY_ONLY=1`.