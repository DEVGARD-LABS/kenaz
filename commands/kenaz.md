---
name: kenaz
description: Audita la seguridad de un plugin o MCP server antes de instalarlo. Soporta cache SHA-256, inventario de herramientas auditadas con detección de rug pulls, y self-test. El auditor oficial de ZYRO.
arguments:
  - name: plugin
    description: "Nombre del plugin (ej: security-guidance), ruta local, o 'self' para self-test"
    required: true
allowed-tools: Read, Glob, Grep, Bash, Agent, mcp__brain-local__brain_add
---

# /kenaz — Auditoría de seguridad antes de instalar

Audita el plugin o MCP server `$ARGUMENTS` antes de instalarlo.

### 0. Self-test (solo si $ARGUMENTS == "self")

Si el argumento es `self`, audita los propios archivos de Kenaz (`~/.claude/agents/kenaz.md`, `~/.claude/commands/kenaz.md`) y reporta si el auditor ha sido comprometido. También ejecuta:
```bash
bash ~/.claude/scripts/plugin-inventory.sh --check
bash ~/.claude/scripts/plugin-inventory.sh --check-mcps
```

### 1. Verificar caché SHA-256

```bash
bash ~/.claude/scripts/audit-cache.sh <plugin-dir>
```

- **CACHE HIT** → mostrar resultado anterior con fecha. Preguntar: "¿Re-auditar? El contenido no ha cambiado desde la última auditoría."
- **CACHE MISS** → continuar con auditoría completa

### 2. Localizar el plugin o MCP server

Busca en este orden:
1. Si `$ARGUMENTS` es una ruta local que existe: usar directamente
2. Si `$ARGUMENTS` es un nombre: buscar en `~/.claude/plugins/marketplaces/claude-plugins-official/plugins/{nombre}/`
3. Si no se encuentra: informar al usuario y parar

### 3. Auditar

Lanza el agente `@kenaz` con la ruta del plugin encontrado. El agente genera el informe con IDs PA-XXX y referencias OWASP AA + MCP.

### 4. Guardar en caché

```bash
bash ~/.claude/scripts/audit-cache.sh <plugin-dir> --write "<VEREDICTO>" '["PA-001","PA-007"]'
```

### 5. Registrar en inventario (SIEMPRE tras auditoría)

Si el veredicto es SEGURO o SEGURO+CÓDIGO:
```bash
bash ~/.claude/scripts/plugin-inventory.sh --register <plugin-dir> "<VEREDICTO>"
```

Esto permite detectar rug pulls futuros: si el plugin cambia después de instalado, `--check` lo detectará.

### 6. Presentar resultado

Muestra el informe completo con el veredicto final.

### 7. Registrar en Brain

Guarda el resultado como neurona:
- type: source
- title: "Auditoría Kenaz: {nombre} — {VEREDICTO}"
- content: resumen del informe en 2-3 líneas + reglas detectadas
- tags: ["kenaz-audit", "seguridad", "{nombre-del-plugin}"]

### 8. Si es SEGURO o SEGURO+CÓDIGO

Pregunta al usuario si quiere activar el plugin.

### Si es NO_INSTALAR

Rechazar sin excepción. No preguntar al usuario si quiere instalarlo de todas formas.

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
