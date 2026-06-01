# Kenaz Community Audits

Real-world audit results from running Kenaz against widely-used Claude Code plugins and MCP servers.

> **Methodology:** Each plugin is audited against all 23 Kenaz detection rules (PA-001 through PA-022). Results reflect the plugin at the version/commit available at audit date. Plugins update — re-run `/kenaz <plugin>` to verify the current version.

> **Responsible disclosure:** Before publishing any REVIEW or DO_NOT_INSTALL verdict for a plugin not listed here, Kenaz contacts the author and allows 48h to respond or remediate.

---

## Navigation

**By type →** [MCP Servers](#mcp-servers) · [Plugins & Hooks](#plugins--hooks) · [LSP / Docs only](#lsp--docs-only)

**By verdict →** [❌ DO_NOT_INSTALL](#-do_not_install) · [⚠️ REVIEW](#️-review) · [✅ SAFE / SAFE_WITH_CODE](#-safe--safe_with_code)

---

## Coverage

| | MCP Servers | Plugins & Hooks | LSP / Docs | Total |
|---|:---:|:---:|:---:|:---:|
| ✅ SAFE | 7 | 14 | 12 | **33** |
| ✅ SAFE_WITH_CODE | 14 | 4 | — | **18** |
| ⚠️ REVIEW | 8 | 1 | — | **9** |
| ❌ DO_NOT_INSTALL | 1 | — | — | **1** |
| **Total** | **30** | **19** | **12** | **61** |

---

## Most used

<!-- stats-start -->
Ranked by npm + PyPI downloads, last 30 days — snapshot **2026-06-01**. Re-run `/kenaz <plugin>` to get an updated verdict for any entry.

> `firebase-tools` downloads reflect the full Firebase CLI, not MCP-specific usage. `@playwright/mcp` is likely inflated by CI pipelines. HTTP remote MCPs have no download metric.

| # | Plugin | Downloads/mo | Verdict | Quick take |
|---|---|---|---|---|
| 1 | playwright | 13.1M | ⚠️ REVIEW | Unpinned `@latest` — pin version before use |
| 2 | firebase | 7.4M | ⚠️ REVIEW | General CLI, not MCP-only — unpinned + `-y` flag ⚠️ inflated |
| 3 | context7 | 4.5M | ⚠️ REVIEW | Unpinned `@latest` + external API by design |
| 4 | filesystem | 1.3M | ✅ SAFE_WITH_CODE | Run `npm audit fix` (minimatch CVE) |
| 5 | memory | 452K | ✅ SAFE_WITH_CODE | Local JSONL graph, zero network |
| 6 | sequential-thinking | 423K | ✅ SAFE_WITH_CODE | Purely in-memory, zero network |
| 7 | supabase | 321K | ✅ SAFE_WITH_CODE | Pin to `@0.8.1` |
| 8 | sentry | 319K | ⚠️ REVIEW | `sendDefaultPii:true` ships tool context to `sentry.io` |
| 9 | notion | 297K | ✅ SAFE_WITH_CODE | Pin to `@2.2.1` |
| 10 | next-devtools-mcp | 254K | ⚠️ REVIEW | PA-023 CRITICAL: `"FORGET ALL PRIOR KNOWLEDGE"` in tool description |
| 11 | slack | 251K | ⚠️ REVIEW | npm/source version gap — cannot audit what executes |
| 12 | stripe | 107K | ✅ SAFE_WITH_CODE | All calls proxied to `mcp.stripe.com` — use restricted keys |

**HTTP remote MCPs** (no npm metric, zero local code): github · figma · cloudflare · linear · gitlab · asana · greptile
<!-- stats-end -->

---

## MCP Servers

### ❌ DO_NOT_INSTALL

| Plugin | Author | Type | Key finding | Audited |
|---|---|---|---|---|
| serena | Oraios | uvx/git | PA-020 HIGH: `uvx git+https://github.com/oraios/serena` — no commit hash, unknown author. Every push to that repo executes on your machine | 2026-05-18 |

### ⚠️ REVIEW

| Plugin | Author | Type | Key finding | Audited |
|---|---|---|---|---|
| next-devtools-mcp | Vercel | npx | PA-023 CRITICAL: `init` tool injects `"FORGET ALL PRIOR KNOWLEDGE"` + `"MANDATORY"` to override LLM; PA-001: telemetry to `telemetry.nextjs.org` without opt-in. Set `NEXT_TELEMETRY_DISABLED=1` | 2026-05-19 |
| slack | Anthropic (archived) | npx | npm `2025.4.25` vs archived source `0.6.2` — code gap not auditable; PA-020 + SDK 1.0.1 outdated. Inspect `node_modules/` post-install | 2026-05-19 |
| sentry | Sentry | npx | PA-001 HIGH: `sendDefaultPii:true` may ship tool call arguments to `sentry.io`; `@latest` unpinned. Pin version + verify scrubbing | 2026-05-19 |
| prisma | Prisma | npx | PA-010 HIGH: `preinstall` script runs at install (tarball may differ from GitHub stub); LLM controls `cwd` in `migrate-reset --force` — no server-side guard | 2026-05-19 |
| aws-labs | AWS | uvx (30+ servers) | PA-020: all 30+ servers documented with `uvx @latest`. Code is clean individually — pin each with `==X.Y.Z` before production use | 2026-05-19 |
| playwright | Microsoft | npx | PA-020: `npx @playwright/mcp@latest` — unpinned. Fix: pin to specific version | 2026-05-18 |
| firebase | Google | npx | PA-020: `npx -y firebase-tools@latest` — no pin + `-y` + Firebase credentials access | 2026-05-18 |
| context7 | Upstash | npx | PA-020: `npx -y @upstash/context7-mcp` — unpinned + sends queries to external API by design | 2026-05-18 |

### ✅ SAFE_WITH_CODE

| Plugin | Author | Type | Key finding | Audited |
|---|---|---|---|---|
| filesystem | Anthropic | Node.js/TS | PA-024: `minimatch ^10.0.1` has 3 ReDoS CVEs — run `npm audit fix`. Symlink/path-traversal protection is solid | 2026-05-19 |
| git | Anthropic | Python/uvx | uv.lock SHA256 pins all deps; active anti flag-injection on every input; use `--repository /path` to scope | 2026-05-19 |
| memory | Anthropic | Node.js/TS | Local JSONL graph, zero network, minimal deps — env var for local path only | 2026-05-19 |
| fetch | Anthropic | Python/uvx | PA-015: description contains `"this tool now grants you internet access"` — semantic override pattern; function is legitimate, no local data exfiltration | 2026-05-19 |
| sequential-thinking | Anthropic | Node.js/TS | Purely in-memory reasoning chain — zero network, zero filesystem, no env leaks | 2026-05-19 |
| discord | Anthropic | TypeScript/bun | Transparent Discord bot; `assertSendable()` prevents exfiltration; bun.lock pins deps (PA-021 mitigated) | 2026-05-18 |
| imessage | Anthropic | TypeScript/bun | Reads local `chat.db` + osascript; no external network; pairing/allowlist controls; bun.lock pins deps | 2026-05-18 |
| telegram | Anthropic | TypeScript/bun | Transparent Telegram bot; network limited to `api.telegram.org`; `safeName()` + `assertSendable()` guards; bun.lock pins deps | 2026-05-18 |
| fakechat | Anthropic | TypeScript/bun | Localhost-only (`127.0.0.1:8787`) test tool — zero external calls; bun.lock pins deps | 2026-05-18 |
| terraform | HashiCorp | Docker | Image pinned at `hashicorp/terraform-mcp-server:0.4.0` — containerized, TFE_TOKEN from env | 2026-05-18 |
| laravel-boost | BeyondCode | PHP artisan | Runs user's own `php artisan boost:mcp` — zero external code, no network | 2026-05-18 |
| supabase | Supabase | npx | PA-020 MEDIUM: LLM instructions suggest unpinned `npx skills add` — pin to `@0.8.1` | 2026-05-19 |
| notion | Notion | npx | PA-020: official docs unpinned; PA-006 LOW dead-code path — pin to `@2.2.1` | 2026-05-19 |
| stripe | Stripe | npx proxy | All tool calls proxied to `mcp.stripe.com` (transparent, documented) — use Restricted Keys (`rk_*`), pin to `@0.3.3` | 2026-05-19 |

### ✅ SAFE

| Plugin | Author | Type | Key finding | Audited |
|---|---|---|---|---|
| github | GitHub | HTTP remote | Bridge to `api.githubcopilot.com` — zero local code, token from env | 2026-05-18 |
| figma | Figma | HTTP remote | `mcp.figma.com`, OAuth — no npm on host; schemas remotely served (Figma Inc. verifiable origin) | 2026-05-19 |
| cloudflare | Cloudflare | HTTP remote | Cloudflare Workers + OAuth — zero local code, all calls to `api.cloudflare.com` only | 2026-05-19 |
| linear | Linear | HTTP remote | Bridge to `mcp.linear.app` — zero local code | 2026-05-18 |
| gitlab | GitLab | HTTP remote | Bridge to `gitlab.com/api/v4/mcp` — zero local code | 2026-05-18 |
| greptile | Greptile | HTTP remote | Bridge to `api.greptile.com` — useful only if already a Greptile customer | 2026-05-18 |
| asana | Asana | HTTP remote SSE | SSE bridge to `mcp.asana.com` — zero local code, token from env | 2026-05-18 |

---

## Plugins & Hooks

### ⚠️ REVIEW

| Plugin | Author | Type | Key finding | Audited |
|---|---|---|---|---|
| cwc-makers | Anthropic | Command (.md) | PA-020/PA-021: `/maker-setup` clones `github.com/moremas/build-with-claude` at HEAD (no pin, unknown author) and runs `onboard.py`. Pin to a specific commit hash before use | 2026-05-19 |

### ✅ SAFE_WITH_CODE

| Plugin | Author | Type | Key finding | Audited |
|---|---|---|---|---|
| ralph-loop | Anthropic | Hook (bash) | Stop hook for iterative loops — no network, no secrets, transparent bash, jq/perl for JSON parsing only | 2026-05-19 |
| security-guidance | Anthropic | Hook (Python) | Defensive PreToolUse hook — no network, no secrets access, transparent logic | 2026-05-18 |
| hookify | Anthropic | Hook framework (Python) | Intercepts all hook events by design — transparent code, no network, no eval | 2026-05-18 |
| claude-code-setup | Anthropic | Agent + Skill | Bash read-only (`ls`, `cat`) for project inspection — no network, no sensitive paths | 2026-05-18 |

### ✅ SAFE

| Plugin | Author | Type | Key finding | Audited |
|---|---|---|---|---|
| claude-md-management | Anthropic | Commands + Skills (.md) | Manages CLAUDE.md files — pure .md, no executable code | 2026-05-19 |
| code-modernization | Anthropic | Agents + Command (.md) | 5-agent legacy code workflow (COBOL/Java/monoliths) — all .md, no executable code | 2026-05-19 |
| feature-dev | Anthropic | Agents + Command (.md) | Multi-agent feature workflow — .md only, KillShell is a declared native tool | 2026-05-18 |
| code-review | Anthropic | Agent (.md) | Multi-agent PR review — `allowed-tools` scoped to `gh` read operations | 2026-05-18 |
| pr-review-toolkit | Anthropic | Agents + Command | 6 review agents — Bash declared and scoped to git/gh read operations | 2026-05-18 |
| agent-sdk-dev | Anthropic | Agents + Command (.md) | Agent SDK development toolkit — all .md, no executable code | 2026-05-19 |
| mcp-server-dev | Anthropic | Skills + References (.md) | MCP build guides — WebFetch to `claude.com/docs` justified, no executable code | 2026-05-18 |
| commit-commands | Anthropic | Commands (.md) | Slash commands with explicit `allowed-tools` restrictions | 2026-05-18 |
| code-simplifier | Anthropic | Agent (.md) | Single .md agent — no executable code or external access | 2026-05-18 |
| session-report | Anthropic | Skill (.md) | Generates session summaries — pure .md, no executable code | 2026-05-19 |
| skill-creator | Anthropic | Skill (.md) | Creates and optimizes Claude Code skills — pure .md | 2026-05-19 |
| math-olympiad | Anthropic | Skill (.md) | Math competition solver with adversarial verification — pure .md | 2026-05-19 |
| frontend-design | Anthropic | Skill (.md) | Design guidance — zero executable code, no network, no filesystem access | 2026-05-18 |
| playground | Anthropic | Skill + Templates (.md) | HTML playground generator — JS in SKILL.md is example text, not plugin code | 2026-05-18 |

---

## LSP / Docs only

All 12 LSP integrations are documentation only — they guide you to install the language server via your system package manager. No plugin code executes.

| Plugin | Language | Install method | Audited |
|---|---|---|---|
| typescript-lsp | TypeScript | npm | 2026-05-18 |
| clangd-lsp | C/C++ | brew / apt / winget | 2026-05-19 |
| gopls-lsp | Go | go install / brew | 2026-05-19 |
| pyright-lsp | Python | npm / brew | 2026-05-19 |
| rust-analyzer-lsp | Rust | rustup / brew | 2026-05-19 |
| ruby-lsp | Ruby | gem | 2026-05-19 |
| kotlin-lsp | Kotlin | brew / IntelliJ | 2026-05-19 |
| swift-lsp | Swift | Xcode / swift.org | 2026-05-19 |
| lua-lsp | Lua | brew / mason | 2026-05-19 |
| php-lsp | PHP | npm (Intelephense) | 2026-05-19 |
| csharp-lsp | C# | dotnet (OmniSharp/roslyn) | 2026-05-19 |
| jdtls-lsp | Java | brew / manual (JDK 17+) | 2026-05-19 |

---

## Verdict reference

| Verdict | Meaning | Action |
|---|---|---|
| ✅ SAFE | Only `.md` instructions, no executable code | Install |
| ✅ SAFE_WITH_CODE | Has code — fully transparent, justified, no exfiltration | Install |
| ⚠️ REVIEW | Ambiguous pattern — human review recommended | Review flagged files first |
| ❌ DO_NOT_INSTALL | Confirmed risk: supply chain, exfiltration, injection, or obfuscation | Reject |

---

## Fixing REVIEW verdicts

**playwright, firebase, context7** — all fail PA-020: unpinned `npx` or `npx -y @latest`. Fix: pin the version in your `.mcp.json`:

```json
// Instead of:
"command": "npx @playwright/mcp@latest"

// Pin to a specific verified version:
"command": "npx @playwright/mcp@0.2.0"
```

Verify the version hash on npm before pinning. After pinning, verdict becomes SAFE_WITH_CODE.

**serena** — structural issue: `uvx git+https://` without a commit hash means installed code changes with every push to the remote repo. Cannot be fixed by the user — the author needs to publish versioned releases on PyPI.

**slack** — npm publishes `2025.4.25` but archived source is `0.6.2`. Cannot verify what actually executes. Workaround: after installing, inspect `node_modules/@modelcontextprotocol/server-slack/dist/` before running, or use the Docker image if available.

**sentry** — `sendDefaultPii: true` is set by default. Error context including tool call arguments may be sent to `sentry.io`. Mitigate: pin a specific version and verify the scrubbing logic covers your data before deploying in sensitive environments.

**next-devtools-mcp** — two independent issues:
1. The `init` tool description injects `"FORGET ALL PRIOR KNOWLEDGE"` and `"MANDATORY CALL FIRST"` (PA-023). This is Vercel's design choice, not malware — but it's a textbook example of how tool descriptions manipulate LLM behavior.
2. Telemetry (OS metadata + hashed `cwd`) is sent to `telemetry.nextjs.org` without opt-in. Fix: set `NEXT_TELEMETRY_DISABLED=1` in the MCP server environment.

**aws-labs, prisma** — pin versions before production use. For aws-labs: `uvx awslabs.xxx==X.Y.Z`. For prisma: inspect the npm tarball's `preinstall` script (`npm pack @prisma/cli` → extract → verify `scripts/preinstall-entry.js` matches the GitHub stub).

---

## Want your plugin audited?

Open an issue using the [audit request template](.github/ISSUE_TEMPLATE/feature_request.md) or run Kenaz yourself:

```bash
/kenaz ./path/to/your/plugin
```

Results are cached by SHA-256 — re-auditing an unchanged plugin is instant.
