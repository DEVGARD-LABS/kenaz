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

## Sesión 2026-05-19 — Gran Audit + AUDITS.md estructurado + SSH multi-cuenta + GitHub Action stats

### Cambios realizados
- [x] **Gran audit comunitario** — 61 entradas en AUDITS.md (30 MCPs + 19 plugins + 12 LSP/docs)
  - Bloque 1-3: 39 plugins oficiales Anthropic (feature-dev, LSPs, ralph-loop, cwc-makers…)
  - Bloque 4: 7 MCPs externos (asana, terraform, laravel-boost, fakechat, discord, imessage, telegram)
  - Bloque 5: 5 core MCPs de modelcontextprotocol/servers (filesystem, git, memory, fetch, sequential-thinking)
  - Bloque 6: 10 MCPs terceros (Figma, Supabase, Notion, Slack, Stripe, Sentry, AWS, Cloudflare, Vercel, Prisma)
- [x] **AUDITS.md reestructurado** — navegación por tipo (MCP/Plugin/LSP) y por veredicto (DO_NOT_INSTALL→REVIEW→SAFE), matriz de cobertura, sección "Most used" con datos reales npm+PyPI
- [x] **scripts/update-stats.py** — fetcha npm + PyPI weekly, actualiza tabla "Most used" entre markers HTML
- [x] **.github/workflows/update-stats.yml** — GitHub Action cron lunes 09:00 UTC + workflow_dispatch
- [x] **SSH multi-cuenta** — claves `id_yidev` (0001-YIDev) + `id_devgard` (DEVGARD-LABS), `~/.ssh/config` con host aliases, auto-routing por remote URL sin gh auth switch
- [x] **Fork privado** — `0001-YIDev/kenaz` privado como sandbox, `upstream` → DEVGARD-LABS producción
- [x] **Remote URL** → `git@github-devgard:DEVGARD-LABS/kenaz.git` (SSH)
- [x] **golden-set/malicious** restaurado al repo público (decisión transparencia)
- [x] **validate-golden-set.sh** — arreglado para funcionar sin categoría malicious (dynamic CATEGORIES array)

### Hallazgos de audit destacados
- `next-devtools-mcp` (Vercel): PA-023 CRITICAL — `init` tool inyecta `"FORGET ALL PRIOR KNOWLEDGE"`
- `sentry`: PA-001 HIGH — `sendDefaultPii:true` envía contexto de tool calls a sentry.io
- `slack`: discrepancia npm 2025.4.25 vs fuente archivada 0.6.2 — código no auditable
- `prisma`: PA-010 HIGH — `preinstall` script en tarball puede diferir del repo
- `filesystem` (Anthropic): PA-024 — minimatch ^10.0.1 cubre 3 CVEs ReDoS HIGH
- `fetch` (Anthropic): PA-015 — description contiene override semántico LLM

### Commits de sesión
- audit(bloque1-4): plugins oficiales + externos
- audit(bloque5): core MCPs modelcontextprotocol/servers
- audit(bloque6): 10 MCPs terceros
- refactor(audits): AUDITS.md con navegación y filtros
- feat(stats): GitHub Action + script update-stats.py con SSL fix macOS
- chore: SSH config + fork privado + remote URL actualizado

### Estado: AUDITS.md v1 completo, auto-stats activo, SSH multi-cuenta operativo

## Gap conocido — 2026-05-03

**`ci-audit.sh` análisis ciego:** el modo CI invoca `claude -p` pasándole solo la ruta del plugin. Claude no tiene acceso a herramientas (Read/Glob/Grep) así que no puede leer los archivos reales — el análisis es superficial comparado con el agente `/audit-plugin` que sí usa herramientas completas.

- **Workaround actual:** usar `/audit-plugin` dentro de Claude Code para análisis completo
- **Fix pendiente:** leer los archivos con bash antes de pasárselos a Claude, o invocar el agente completo
- **Tarea:** `t_horus-ciaudit-agent-upgrade_h1a2b3` en TAREAS.json
