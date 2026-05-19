# Kenaz Community Audits

Real-world audit results from running Kenaz against widely-used Claude Code plugins and MCP servers.

> **Methodology:** Each plugin is audited against all 23 Kenaz detection rules (PA-001 through PA-022). Results reflect the plugin at the version/commit available at audit date. Plugins update — re-run `/kenaz <plugin>` to verify the current version.

> **Responsible disclosure:** Before publishing any REVIEW or DO_NOT_INSTALL verdict for a plugin not listed here, Kenaz contacts the author and allows 48h to respond or remediate. We do not publish verdicts designed to harm — we publish them to protect users.

---

## Results

| Plugin | Author | Type | Verdict | Key finding | Audited |
|---|---|---|---|---|---|
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

---

## Want your plugin audited?

Open an issue using the [audit request template](.github/ISSUE_TEMPLATE/feature_request.md) or run Kenaz yourself:

```bash
/kenaz ./path/to/your/plugin
```

Results are cached by SHA-256 — re-auditing an unchanged plugin is instant.
