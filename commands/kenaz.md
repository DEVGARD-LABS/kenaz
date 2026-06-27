---
name: kenaz
description: Audita la seguridad de un plugin, MCP server o repositorio de GitHub antes de instalarlo o usarlo. Soporta URL remota, cache SHA-256, inventario con detección de rug pulls, y self-test. El auditor oficial de ZYRO.
arguments:
  - name: target
    description: "URL de GitHub (https://github.com/owner/repo), nombre del plugin (ej: security-guidance), ruta local, o 'self' para self-test"
    required: true
allowed-tools: Read, Glob, Grep, Bash, Agent, mcp__brain-local__brain_add
---

# /kenaz — Auditoría de seguridad antes de instalar

Audita el target `$ARGUMENTS` antes de instalarlo o usarlo.

### 0. Self-test (solo si $ARGUMENTS == "self")

Si el argumento es `self`, audita los propios archivos de Kenaz (`~/.claude/agents/kenaz.md`, `~/.claude/commands/kenaz.md`) y reporta si el auditor ha sido comprometido. También ejecuta:
```bash
bash ~/.claude/scripts/plugin-inventory.sh --check
bash ~/.claude/scripts/plugin-inventory.sh --check-mcps
```

### 1. Detectar URL de GitHub (NUEVO)

Si `$ARGUMENTS` matchea `^https?://github\.com/[^/]+/[^/]+/?$`:

1. Clonar y clasificar el repo (cross-platform — usa Node.js, no bash):
   ```bash
   node ~/.claude/scripts/kenaz-fetch-and-classify.mjs "$ARGUMENTS"
   ```
2. Parsear el JSON devuelto. Campos clave:
   - `path` → ruta local del clone (sirve como `<plugin-dir>` para el resto del flujo)
   - `repo_type` → uno de: `plugin-claude-code`, `mcp-server`, `cli-tool`, `library`, `webapp`, `dataset`, `docs`, `mixed`
   - `stack` → array de tecnologías detectadas (node, python, rust, …)
   - `manifests` → archivos manifest encontrados
   - `description` → primeras líneas del README
   - `total_files`, `total_size_kb`, `extensions`, `top_dirs`
3. Mostrar al usuario un resumen **antes de la auditoría profunda**:
   ```
   ## 📦 Lo que voy a auditar

   **Repo:** <owner>/<repo>
   **Categoría:** <repo_type>
   **Stack:** <stack>
   **Tamaño:** <total_files> archivos · <total_size_kb> KB
   **Top dirs:** <top_dirs>
   **Descripción (README):** <description>
   ```
4. Continuar con paso 2 usando `path` como `<plugin-dir>`.

Si el clone falla, mostrar el error JSON (`invalid_url`, `clone_failed`, `empty_repo`, `git_not_found`) y parar.

### 2. Verificar caché SHA-256

```bash
bash ~/.claude/scripts/audit-cache.sh <plugin-dir>
```

- **CACHE HIT** → mostrar resultado anterior con fecha. Preguntar: "¿Re-auditar? El contenido no ha cambiado desde la última auditoría."
- **CACHE MISS** → continuar con auditoría completa

### 3. Localizar el plugin (si NO viene de URL)

Si `$ARGUMENTS` NO era URL, busca en este orden:
1. Si `$ARGUMENTS` es una ruta local que existe: usar directamente
2. Si `$ARGUMENTS` es un nombre: buscar en `~/.claude/plugins/marketplaces/claude-plugins-official/plugins/{nombre}/`
3. Si no se encuentra: informar al usuario y parar

### 4. Auditar

Lanza el agente `@kenaz` con la ruta del target encontrado. **Si vino de URL, pasa también el JSON de clasificación como contexto adicional** — el agente lo usa para decidir qué reglas aplicar (datasets de texto → PA-015/016, código → PA-001..024).

El agente genera el informe con IDs PA-XXX y referencias OWASP AA + MCP.

### 5. Guardar en caché

```bash
bash ~/.claude/scripts/audit-cache.sh <plugin-dir> --write "<VEREDICTO>" '["PA-001","PA-007"]'
```

### 6. Registrar en inventario (SIEMPRE tras auditoría)

Si el veredicto es SEGURO o SEGURO+CÓDIGO:
```bash
bash ~/.claude/scripts/plugin-inventory.sh --register <plugin-dir> "<VEREDICTO>"
```

Esto permite detectar rug pulls futuros: si el target cambia después de instalado, `--check` lo detectará.

### 7. Presentar resultado

Muestra el informe completo con el veredicto final. Si vino de URL, incluye en cabecera el resumen "Lo que voy a auditar" del paso 1.

### 8. Registrar en Brain

Guarda el resultado como neurona:
- type: security
- title: "Auditoría Kenaz: {nombre} — {VEREDICTO}"
- content: resumen del informe en 2-3 líneas + reglas detectadas + (si vino de URL) URL original
- tags: ["kenaz-audit", "seguridad", "{nombre}"]

### 9. Si es SEGURO o SEGURO+CÓDIGO

Pregunta al usuario si quiere activar el plugin. Si vino de URL y es solo lectura (dataset/docs), explícalo: no hay "instalación" — solo decisión de si leer/usar el contenido.

### Si es NO_INSTALAR

Rechazar sin excepción. No preguntar al usuario si quiere instalarlo de todas formas. Si vino de URL, ofrecer `rm -rf` del clone temporal.

---

## Lista de herramientas auditadas

```bash
bash ~/.claude/scripts/plugin-inventory.sh --list
```

## Detectar rug pulls en herramientas ya instaladas

```bash
bash ~/.claude/scripts/plugin-inventory.sh --check
bash ~/.claude/scripts/plugin-inventory.sh --check-mcps
```
