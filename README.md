# Kenaz

> Security auditor for Claude Code plugins, MCP servers, and agents — before you install anything.

Detects **23 attack patterns** (PA-001..PA-024, PA-013 reserved) mapped to **OWASP Agentic Top 10 2026** and **OWASP MCP Top 10 (beta)**. Runs entirely on your machine using the Claude model you already have. Free, offline, no account required.

---

## Install

```bash
claude plugin install https://github.com/aurvang/kenaz
```

## Usage

```bash
# Audit a plugin before installing
/kenaz <plugin-name>

# Audit a local directory
/kenaz /path/to/plugin

# Verify the auditor itself hasn't been tampered with
/kenaz self

# CI mode — exits 1 if DO_NOT_INSTALL, 0 otherwise
bash scripts/ci-audit.sh /path/to/plugin
```

---

## What it detects

| Category | Rules | Examples |
|---|---|---|
| **Exfiltration** | PA-001..PA-003, PA-018 | HTTP to unknown URLs, `process.env` leak, MCP params interception |
| **Sensitive read** | PA-004..PA-006 | `.env` access, `~/.ssh` reads, out-of-scope file access |
| **Hidden execution** | PA-007..PA-010, PA-019, PA-022 | `eval()`, shell exec, lifecycle scripts, hook injection |
| **Obfuscation** | PA-011, PA-012, PA-017 | Minified code, base64 payloads, `String.fromCharCode` |
| **Prompt injection** | PA-015..PA-016 | `.md` instruction hijacking, hidden HTML comments |
| **Supply chain** | PA-020..PA-021 | Unversioned `npx -y`, wildcard deps, private registries |

---

## Verdicts

| Verdict | Meaning | Action |
|---|---|---|
| `SAFE` | Only `.md` instructions, no executable code | ✅ Install |
| `SAFE_WITH_CODE` | Has code, fully transparent and justified | ✅ Install |
| `REVIEW` | Ambiguous patterns — human review needed | ⚠️ Review flagged files |
| `DO_NOT_INSTALL` | Confirmed exfiltration, injection, or obfuscation | ❌ Reject |

---

## How it compares

| Feature | kenaz | Snyk mcp-scan | AgentShield | AgentSeal | Semgrep |
|---|---|---|---|---|---|
| **Price** | Free | Requires Snyk account | $19/mo | $19/mo or $199 one-shot | $30/mo/contributor |
| **100% offline** | ✅ | ❌ Cloud | ❌ Cloud | ❌ Cloud | ❌ Cloud |
| **Claude Code native** | ✅ `/kenaz` | ❌ | ❌ | ❌ | ❌ |
| **Prompt injection scan (.md)** | ✅ PA-015, PA-016 | ❌ | Partial | ❌ | ❌ |
| **MCP params exfiltration** | ✅ PA-018 | Partial | ❌ | ❌ | ❌ |
| **Hook injection detection** | ✅ PA-019 | ❌ | ❌ | ❌ | ❌ |
| **Base64/charcode deobfuscation** | ✅ Active | Partial | ❌ | ❌ | Partial |
| **SHA-256 audit cache** | ✅ | ❌ | ❌ | ✅ | ❌ |
| **CI mode (exit code)** | ✅ | ✅ | ❌ | ✅ | ✅ |
| **OWASP Agentic Top 10 mapping** | ✅ AA:01..AA:10 | Partial | ❌ | ❌ | ❌ |
| **Self-test** | ✅ | ❌ | ❌ | ❌ | ❌ |
| **No npm dependencies** | ✅ | ❌ | ❌ | ❌ | ❌ |

---

## Features

**SHA-256 cache** — Already audited this plugin? If the content hasn't changed, re-auditing is skipped instantly. Results stored in `~/.claude/audit-cache/`.

**Deobfuscation** — Decodes `base64` payloads and `String.fromCharCode()` sequences at analysis time, then reports what's inside before emitting a verdict.

**CI mode** — `ci-audit.sh` returns exit code `1` if verdict is `DO_NOT_INSTALL`. Add it to your pipeline before any plugin installation step.

**Self-test** — `/kenaz self` makes the auditor audit its own directory. Useful to verify integrity after updates.

---

## Rules catalog

Full rules with detection patterns, malicious/benign examples, and false-positive guidance:
[`rules/PA-RULES.md`](rules/PA-RULES.md)

---

## Test suite

Validate the golden set structure without invoking the LLM:

```bash
bash tests/validate-golden-set.sh --verbose
# 99 checks, 0 failures
```

---

## Why this exists

The Claude Code plugin ecosystem is growing fast. In April 2026:
- CVE-2025-6514 demonstrated real MCP server exfiltration in production
- 36.7% of MCP servers tested had SSRF vulnerabilities (research, Q1 2026)
- Snyk acquired Invariant Labs specifically for MCP security
- Lakera was acquired for $300M — agent security is real infrastructure now

Most tools are cloud-based and expensive. Kenaz is the free, offline, Claude-native option.

---

## License

MIT — see [LICENSE](LICENSE)
