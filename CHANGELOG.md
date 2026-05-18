# Changelog

All notable changes to Kenaz are documented here.
Format: [Keep a Changelog](https://keepachangelog.com/en/1.0.0/) — [Semantic Versioning](https://semver.org/spec/v2.0.0.html)

---

## [1.1.0] — 2026-05-16

### Added

**Rules catalog (23 rules)**
- PA-001..PA-003: Exfiltration (HTTP, WebSocket, env vars)
- PA-004..PA-006: Sensitive read (.env, credential stores, out-of-scope files)
- PA-007..PA-010: Hidden execution (eval, shell, dynamic import, lifecycle scripts)
- PA-011..PA-012: Obfuscation (minified code, base64 payloads)
- PA-014: Excessive permissions
- PA-015..PA-016: Prompt injection (markdown, hidden instructions)
- PA-017: Hex/charcode obfuscation (String.fromCharCode)
- PA-018: MCP params exfiltration
- PA-019: Claude Code hook injection (PreToolUse/PostToolUse)
- PA-020: Unversioned package execution (npx -y without @version)
- PA-021: Dependency red flags (wildcards, postinstall, private registries)
- PA-022: Shell command injection (template literals without sanitization)
- PA-023: Tool poisoning semantic (instructions in metadata fields)
- PA-024: Known vulnerable dependency (advisory database lookups)
- PA-013 reserved (signal context for PA-011, not actionable alone)

**Golden set (14 plugins)**
- 3 safe: formatter, git-helper, linter
- 8 malicious: exfil-env, eval-b64, prompt-inject, hex-obfuscation, mcp-exfil, hook-inject, tool-poisoning-manifest, vulnerable-dep
- 3 ambiguous: analytics, curl-wrapper, npx-unversioned

**Infrastructure**
- `audit-cache.sh`: SHA-256 cache — skip re-auditing unchanged plugins
- `ci-audit.sh`: CI mode with exit code 0/1 for pipeline integration
- `commands/kenaz.md`: slash command with cache + self-test
- `audit-to-sarif.js`: convert audit results to SARIF 2.1.0 for GitHub Code Scanning
- `plugin-inventory.sh`: SHA-256 inventory with rug-pull detection (`--check`, `--check-mcps`)
- `yara-scan.sh`: signature-based pre-pass (native YARA or grep fallback)
- OWASP Agentic Top 10 2026 + OWASP MCP Top 10 (beta) mapping for every rule

### Security

- Agent is 100% read-only: never executes or modifies audited plugin files
- Cache writes only to `~/.claude/audit-cache/`
- Zero npm dependencies — no supply chain surface
- Self-test: `/kenaz self` verifies the auditor hasn't been tampered with

---

## [Unreleased]

### Known gaps

- **`ci-audit.sh` blind analysis** — current CI mode sends only the plugin *path* to Claude via `claude -p`. Claude cannot read the actual plugin files (no tool access), so the analysis is shallower than the interactive `/kenaz` skill which runs a full agent with Read/Glob/Grep/Bash. Planned fix: bundle file contents into the prompt before invoking `claude -p`, or invoke the agent via `claude --agent`.

### Future work

- GitHub Action for automated PR auditing
- Support for arbitrary MCP server directories
- Expanded signature database for known supply-chain incidents
