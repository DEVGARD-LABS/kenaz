# Kenaz Community Audits

Real-world audit results from running Kenaz against widely-used Claude Code plugins and MCP servers.

> **Methodology:** Each plugin is audited against all 23 Kenaz detection rules (PA-001 through PA-022). Results reflect the plugin at the version/commit available at audit date. Plugins update — re-run `/kenaz <plugin>` to verify the current version.

> **Responsible disclosure:** Before publishing any REVIEW or DO_NOT_INSTALL verdict for a plugin not listed here, Kenaz contacts the author and allows 48h to respond or remediate. We do not publish verdicts designed to harm — we publish them to protect users.

---

## Results

| Plugin | Author | Type | Verdict | Key finding | Audited |
|---|---|---|---|---|---|
| claude-md-management | Anthropic | Commands + Skills (.md) | ✅ SAFE | Manages CLAUDE.md files across sessions — pure .md instructions, no executable code | 2026-05-19 |
| code-modernization | Anthropic | Agents + Command (.md) | ✅ SAFE | 5-agent workflow for legacy code (COBOL/Java/monoliths) — all .md agents, no executable code | 2026-05-19 |
| ralph-loop | Anthropic | Hook (bash) | ✅ SAFE_WITH_CODE | Stop hook intercepts session exit for iterative loops — no network, no secrets, transparent bash logic, jq/perl for JSON parsing only | 2026-05-19 |
| session-report | Anthropic | Skill (.md) | ✅ SAFE | Pure .md skill for generating session summaries — no executable code | 2026-05-19 |
| skill-creator | Anthropic | Skill (.md) | ✅ SAFE | Pure .md skill for creating and optimizing Claude Code skills — no executable code | 2026-05-19 |
| agent-sdk-dev | Anthropic | Agents + Command (.md) | ✅ SAFE | Agent SDK development toolkit — all .md, no executable code | 2026-05-19 |
| math-olympiad | Anthropic | Skill (.md) | ✅ SAFE | Math competition solver with adversarial verification — pure .md skill, no executable code | 2026-05-19 |
| cwc-makers | Anthropic | Command (.md) | ⚠️ REVIEW | PA-020/PA-021: `/maker-setup` clones `github.com/moremas/build-with-claude` at HEAD (no pin) and executes `onboard.py` — unknown author `moremas`, unpinned. Fix: pin to a specific commit hash before use | 2026-05-19 |
| feature-dev | Anthropic | Agents + Command (.md) | ✅ SAFE | Multi-agent feature workflow (explorer/architect/reviewer) — .md only, no executable code, KillShell is a declared native tool not custom code | 2026-05-18 |
| frontend-design | Anthropic | Skill (.md) | ✅ SAFE | Pure .md design guidance — zero executable code, no network, no filesystem access | 2026-05-18 |
| mcp-server-dev | Anthropic | Skills + References (.md) | ✅ SAFE | Build guides for MCP servers — WebFetch to `claude.com/docs` is documented and justified, no executable code | 2026-05-18 |
| playground | Anthropic | Skill + Templates (.md) | ✅ SAFE | HTML playground generator — JS in SKILL.md is example text to guide generation, not plugin code | 2026-05-18 |
| security-guidance | Anthropic | Hook (Python) | ✅ SAFE_WITH_CODE | Defensive PreToolUse hook — no network, no secrets access, transparent logic | 2026-05-18 |
| commit-commands | Anthropic | Commands (.md) | ✅ SAFE | Pure .md slash commands with explicit `allowed-tools` restrictions | 2026-05-18 |
| code-review | Anthropic | Agent (.md) | ✅ SAFE | Multi-agent PR review, `allowed-tools` scoped to `gh` read operations | 2026-05-18 |
| hookify | Anthropic | Hook framework (Python) | ✅ SAFE_WITH_CODE | Intercepts all hook events by design — code is transparent, no network, no eval | 2026-05-18 |
| code-simplifier | Anthropic | Agent (.md) | ✅ SAFE | Single .md agent with no executable code or external access | 2026-05-18 |
| pr-review-toolkit | Anthropic | Agents + Command | ✅ SAFE | 6 review agents, Bash declared and scoped to git/gh read operations | 2026-05-18 |
| typescript-lsp | Anthropic | Docs only | ✅ SAFE | Documentation only — no plugin code, guides user to install public npm packages manually | 2026-05-18 |
| clangd-lsp | Anthropic | Docs only | ✅ SAFE | Documentation only — guides user to install clangd via brew/apt/winget. No plugin code | 2026-05-19 |
| gopls-lsp | Anthropic | Docs only | ✅ SAFE | Documentation only — guides user to install gopls via go install or brew. No plugin code | 2026-05-19 |
| pyright-lsp | Anthropic | Docs only | ✅ SAFE | Documentation only — guides user to install Pyright via npm or brew. No plugin code | 2026-05-19 |
| rust-analyzer-lsp | Anthropic | Docs only | ✅ SAFE | Documentation only — guides user to install rust-analyzer via rustup or brew. No plugin code | 2026-05-19 |
| ruby-lsp | Anthropic | Docs only | ✅ SAFE | Documentation only — guides user to install ruby-lsp via gem. No plugin code | 2026-05-19 |
| kotlin-lsp | Anthropic | Docs only | ✅ SAFE | Documentation only — guides user to install Kotlin LSP via brew or IntelliJ toolchain. No plugin code | 2026-05-19 |
| swift-lsp | Anthropic | Docs only | ✅ SAFE | Documentation only — guides user to install sourcekit-lsp via Xcode or swift.org. No plugin code | 2026-05-19 |
| lua-lsp | Anthropic | Docs only | ✅ SAFE | Documentation only — guides user to install lua-language-server via brew or mason. No plugin code | 2026-05-19 |
| php-lsp | Anthropic | Docs only | ✅ SAFE | Documentation only — guides user to install Intelephense via npm. No plugin code | 2026-05-19 |
| csharp-lsp | Anthropic | Docs only | ✅ SAFE | Documentation only — guides user to install OmniSharp or roslyn via dotnet. No plugin code | 2026-05-19 |
| jdtls-lsp | Anthropic | Docs only | ✅ SAFE | Documentation only — guides user to install Eclipse JDT.LS via brew or manual download. Requires JDK 17+ | 2026-05-19 |
| claude-code-setup | Anthropic | Agent + Skill | ✅ SAFE_WITH_CODE | Bash read-only (ls, cat) for project inspection — no network, no sensitive paths | 2026-05-18 |
| github | GitHub | MCP (HTTP remote) | ✅ SAFE | HTTP bridge to `api.githubcopilot.com` — zero local code, token from env var | 2026-05-18 |
| linear | Linear | MCP (HTTP remote) | ✅ SAFE | HTTP bridge to `mcp.linear.app` — zero local code | 2026-05-18 |
| gitlab | GitLab | MCP (HTTP remote) | ✅ SAFE | HTTP bridge to `gitlab.com/api/v4/mcp` — zero local code | 2026-05-18 |
| greptile | Greptile | MCP (HTTP remote) | ✅ SAFE | HTTP bridge to `api.greptile.com` — only useful if already a Greptile customer | 2026-05-18 |
| playwright | Microsoft | MCP (npx) | ⚠️ REVIEW | PA-020: `npx @playwright/mcp@latest` — no version pin. Fix: pin to specific version | 2026-05-18 |
| firebase | Google | MCP (npx) | ⚠️ REVIEW | PA-020: `npx -y firebase-tools@latest` — no pin + `-y` flag + access to Firebase credentials | 2026-05-18 |
| context7 | Upstash | MCP (npx) | ⚠️ REVIEW | PA-020: `npx -y @upstash/context7-mcp` — no pin + sends queries to external API by design | 2026-05-18 |
| serena | Oraios | MCP (uvx/git) | ❌ DO_NOT_INSTALL | PA-020 HIGH: `uvx git+https://github.com/oraios/serena` — installs from HEAD with no commit hash. Unknown author. Any push to that repo executes on your machine. | 2026-05-18 |
| asana | Asana | MCP (HTTP remote SSE) | ✅ SAFE | HTTP SSE bridge to `mcp.asana.com` — zero local code, token from env var | 2026-05-18 |
| terraform | HashiCorp | MCP (Docker) | ✅ SAFE_WITH_CODE | Docker image pinned at `hashicorp/terraform-mcp-server:0.4.0` — containerized, TFE_TOKEN from env var, no local code to audit | 2026-05-18 |
| laravel-boost | BeyondCode | MCP (PHP artisan) | ✅ SAFE_WITH_CODE | Runs user's own `php artisan boost:mcp` — zero external code, no network, executes code the user already owns and installed | 2026-05-18 |
| fakechat | Anthropic | MCP (TypeScript/bun) | ✅ SAFE_WITH_CODE | Localhost-only test/demo tool bound to `127.0.0.1:8787` — zero external calls, WebSocket UI for simulating chat, bun.lock pins all deps | 2026-05-18 |
| discord | Anthropic | MCP (TypeScript/bun) | ✅ SAFE_WITH_CODE | Transparent Discord bot — token from `~/.claude/channels/discord/.env`, `assertSendable()` prevents state file exfiltration, bun.lock pins deps (PA-021 mitigated) | 2026-05-18 |
| imessage | Anthropic | MCP (TypeScript/bun) | ✅ SAFE_WITH_CODE | Reads local `~/Library/Messages/chat.db` + osascript for sending — no external network, pairing/allowlist access controls, `assertSendable()` guard, bun.lock pins deps | 2026-05-18 |
| telegram | Anthropic | MCP (TypeScript/bun) | ✅ SAFE_WITH_CODE | Transparent Telegram bot — token from env, network limited to `api.telegram.org` (own bot), `safeName()` + `assertSendable()` injection/exfiltration guards, bun.lock pins deps (PA-021 mitigated) | 2026-05-18 |
| filesystem | Anthropic | MCP (Node.js/TS) | ✅ SAFE_WITH_CODE | PA-024: `minimatch ^10.0.1` covers 3 ReDoS CVEs HIGH (GHSA-7r86, GHSA-23c5, GHSA-3ppc) — fix: `npm audit fix` or pin `>=10.2.3`. Logic is safe: symlink protection, path traversal prevention, atomic writes | 2026-05-19 |
| git | Anthropic | MCP (Python/uvx) | ✅ SAFE_WITH_CODE | uv.lock with SHA256 pins all deps; active anti flag-injection defense on every user input; always configure `--repository /path` to restrict repo scope | 2026-05-19 |
| memory | Anthropic | MCP (Node.js/TS) | ✅ SAFE_WITH_CODE | Local JSONL knowledge graph, zero network, minimal deps (SDK only) — env var limited to local path config, no data leaves machine | 2026-05-19 |
| fetch | Anthropic | MCP (Python/uvx) | ✅ SAFE_WITH_CODE | PA-015: tool description contains `"this tool now grants you internet access"` — semantic LLM override pattern. Function is legitimate (fetch URLs to Markdown). No exfiltration of local data. Respects robots.txt | 2026-05-19 |
| sequential-thinking | Anthropic | MCP (Node.js/TS) | ✅ SAFE_WITH_CODE | Purely in-memory reasoning chain — zero network, zero filesystem, no env var leaks, no deps with known advisories | 2026-05-19 |
| figma | Figma | MCP (HTTP remote) | ✅ SAFE | HTTP remote to `mcp.figma.com`, zero local code, OAuth — no npm supply chain on host; tool schemas served remotely (opaque but Figma Inc. is verifiable origin) | 2026-05-19 |
| supabase | Supabase | MCP (npx) | ✅ SAFE_WITH_CODE | PA-020 MEDIUM: server instructions suggest unpinned `npx skills add supabase/agent-skills` to LLM — in shell-enabled environments, downloads latest on every session. Fix: pin to `@0.8.1` | 2026-05-19 |
| notion | Notion | MCP (npx) | ✅ SAFE_WITH_CODE | PA-020: official docs use `npx -y` unpinned; PA-006 LOW (dead code): file upload path accepts unsanitized paths — currently harmless, activates if upload endpoints added. Fix: pin to `@2.2.1` | 2026-05-19 |
| slack | Anthropic (archived) | MCP (npx) | ⚠️ REVIEW | npm publishes `2025.4.25` but archived source is `0.6.2` — cannot audit what actually executes; PA-020 + SDK 1.0.1 outdated. Fix: inspect `node_modules` post-install or use Docker image | 2026-05-19 |
| stripe | Stripe | MCP (npx proxy) | ✅ SAFE_WITH_CODE | PA-020: unpinned + all MCP tool calls proxied verbatim to `mcp.stripe.com` by design (transparent, documented). Use Restricted Keys (`rk_*`), pin to `@0.3.3` | 2026-05-19 |
| sentry | Sentry | MCP (npx) | ⚠️ REVIEW | PA-001 HIGH: `sendDefaultPii: true` sends error context (may include tool call arguments) to `sentry.io` by default without explicit user warning; PA-020: `@latest` unpinned. Fix: pin version + verify scrubbing covers your data | 2026-05-19 |
| aws-labs | AWS | MCP (uvx, 30+ servers) | ⚠️ REVIEW | PA-020: all 30+ servers documented with `uvx @latest` — supply chain unverified at scale. Individual servers (e.g. aws-documentation) are code-clean. Fix: pin each server with `==X.Y.Z` before use in production | 2026-05-19 |
| cloudflare | Cloudflare | MCP (HTTP remote) | ✅ SAFE | 100% HTTP remote (Cloudflare Workers + OAuth), zero local code — no npm supply chain on host, all calls to `api.cloudflare.com` only | 2026-05-19 |
| next-devtools-mcp | Vercel | MCP (npx) | ⚠️ REVIEW | PA-023 CRITICAL: `init` tool description injects `"FORGET ALL PRIOR KNOWLEDGE"` + `"MANDATORY"` imperatives to override LLM behavior; PA-001 HIGH: telemetry (OS metadata + hashed cwd) sent to `telemetry.nextjs.org` without opt-in. Set `NEXT_TELEMETRY_DISABLED=1` | 2026-05-19 |
| prisma | Prisma | MCP (npx) | ⚠️ REVIEW | PA-010 HIGH: `preinstall` script runs at `npm install` (npm tarball may differ from GitHub stub); PA-008: LLM controls `cwd` in `migrate-reset --force` with no server-side confirmation guard | 2026-05-19 |

---

## Verdict reference

| Verdict | Meaning |
|---|---|
| ✅ SAFE | Only `.md` instructions, no executable code |
| ✅ SAFE_WITH_CODE | Has executable code — fully transparent, justified, no network exfiltration |
| ⚠️ REVIEW | Ambiguous pattern — human review recommended before installing |
| ❌ DO_NOT_INSTALL | Confirmed risk: supply chain, exfiltration, injection, or obfuscation |

---

## Fixing REVIEW verdicts

**playwright, firebase, context7** — all three fail on the same rule: unpinned `npx` or `npx -y` with `@latest`. The fix is to pin the version in your local `.mcp.json`:

```json
// Instead of:
"command": "npx @playwright/mcp@latest"

// Pin to a specific verified version:
"command": "npx @playwright/mcp@0.2.0"
```

Verify the version hash on npm before pinning. After pinning, verdict becomes SAFE_WITH_CODE.

**serena** — the issue is structural: `uvx git+https://` without a commit hash means the installed code changes with every push to the remote repo. This cannot be fixed by the user — the author needs to publish versioned releases on PyPI.

**slack** — npm publishes a version (`2025.4.25`) that doesn't match the archived source code (`0.6.2`). Cannot verify what actually executes. Workaround: after installing, inspect `node_modules/@modelcontextprotocol/server-slack/dist/` before running, or use the Docker image if available.

**sentry** — `sendDefaultPii: true` is set in the server's Sentry initialization. This means error context including tool call arguments may be sent to `sentry.io`. To mitigate: pin a specific version and review if the data passing through your Sentry installation is acceptable for Sentry's telemetry.

**next-devtools-mcp** — two independent issues:
1. The `init` tool description contains `"FORGET ALL PRIOR KNOWLEDGE"` and `"MANDATORY CALL FIRST"` imperative override patterns (PA-023). This is a design choice by Vercel, not malware, but it demonstrates how tool descriptions can manipulate LLM behavior.
2. Telemetry to `telemetry.nextjs.org` (OS metadata + hashed `cwd`) runs without opt-in. Fix: set `NEXT_TELEMETRY_DISABLED=1` in the MCP server environment before using.

**aws-labs, prisma** — pin versions before production use. For aws-labs: `uvx awslabs.xxx==X.Y.Z`. For prisma: inspect the npm tarball's `preinstall` script before installing (`npm pack @prisma/cli` → extract → verify `scripts/preinstall-entry.js`).

---

## Want your plugin audited?

Open an issue using the [audit request template](.github/ISSUE_TEMPLATE/feature_request.md) or run Kenaz yourself:

```bash
/kenaz ./path/to/your/plugin
```

Results are cached by SHA-256 — re-auditing an unchanged plugin is instant.
