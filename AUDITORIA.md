# AUDITORIA — Plugin Security Auditor

## Info
- **Inicio:** 2026-04-21
- **Propósito:** Plugin de Claude Code que audita otros plugins/MCP servers por seguridad
- **Stack:** Markdown (agente + skill, sin código ejecutable)
- **Repo:** 0001-YIDev/claude-plugin-auditor

## Sesión 2026-04-21 — Crear y publicar

### Cambios realizados
- [x] plugin.json con metadata
- [x] agents/security-auditor.md — agente auditor (traducido de español a inglés)
- [x] commands/audit.md — skill /audit (traducido)
- [x] README.md profesional con datos de mercado y ejemplo de output
- [x] LICENSE MIT
- [x] Auditoría pre-lanzamiento: 0 español, 0 datos personales, 0 secrets

### Estado: LISTO PARA PUBLICAR

## Sesión 2026-05-18 — Kenaz v1.1.0: wiring completo + rename auditor único

### Cambios realizados
- [x] `scripts/install.sh` — crea symlinks en `~/.claude/` (agents, commands, scripts). Idempotente
- [x] `scripts/check-update.sh` — SessionStart hook: auto-instala si versión cambia, notifica commits remotos via stderr
- [x] `commands/kenaz.md` — flujo completo reescrito: caché SHA-256 → @kenaz audit → inventario → brain → activar
- [x] `/audit-plugin` y `@auditor-plugins` eliminados — Kenaz es el único auditor
- [x] SessionStart hook registrado en `~/.claude/settings.json`
- [x] 5 plugins oficiales Anthropic auditados y registrados en inventario: code-review, feature-dev, frontend-design, mcp-server-dev, pr-review-toolkit (todos SEGURO)
- [x] context7 MCP auditado (SEGURO+CÓDIGO) + instalado
- [x] playwright MCP auditado (SEGURO+CÓDIGO) + instalado

### Estado: v1.1.0 en producción

## Gap conocido — 2026-05-03

**`ci-audit.sh` análisis ciego:** el modo CI invoca `claude -p` pasándole solo la ruta del plugin. Claude no tiene acceso a herramientas (Read/Glob/Grep) así que no puede leer los archivos reales — el análisis es superficial comparado con el agente `/audit-plugin` que sí usa herramientas completas.

- **Workaround actual:** usar `/audit-plugin` dentro de Claude Code para análisis completo
- **Fix pendiente:** leer los archivos con bash antes de pasárselos a Claude, o invocar el agente completo
- **Tarea:** `t_horus-ciaudit-agent-upgrade_h1a2b3` en TAREAS.json
