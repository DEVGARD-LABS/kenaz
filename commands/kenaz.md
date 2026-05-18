---
name: kenaz
description: Audits a Claude Code plugin, MCP server, or AI agent for security risks before installation. Supports SHA-256 cache to skip re-auditing unchanged plugins.
arguments:
  - name: plugin
    description: "Plugin name (e.g. git-helper), local path, or 'self' for self-test"
    required: true
allowed-tools: Read, Glob, Grep, Bash, Agent
---

# /kenaz — Security audit before installing

Audits `$ARGUMENTS` for security risks before installation.

### 0. Self-test (only if $ARGUMENTS == "self")

If the argument is `self`, audit Kenaz's own directory (`~/.claude/plugins/marketplaces/*/kenaz/`) and report whether the auditor itself has been tampered with.

### 1. Check SHA-256 cache

```bash
bash ~/.claude/plugins/marketplaces/claude-plugins-official/plugins/kenaz/scripts/audit-cache.sh <plugin-dir>
```

- **CACHE HIT** → show previous result with date. Ask: "Re-audit? Content hasn't changed since last audit."
- **CACHE MISS** → proceed with full audit

### 2. Locate the plugin

Search in order:
1. If `$ARGUMENTS` is an existing local path: use directly
2. If `$ARGUMENTS` is a name: look in `~/.claude/plugins/marketplaces/claude-plugins-official/plugins/{name}/`
3. If not found: inform the user and stop

### 3. Audit

Launch the `@kenaz` agent with the plugin path. The agent produces a report with PA-XXX rule IDs and OWASP references.

### 4. Save to cache

After the audit, store the result:
```bash
bash <scripts-path>/audit-cache.sh <plugin-dir> --write "<VERDICT>" '["PA-001","PA-007"]'
```

### 5. Present result

Display the full report with the final verdict.

### 6. If SAFE or SAFE_WITH_CODE

Ask the user if they want to activate the plugin.

### If DO_NOT_INSTALL

Reject without exception. Do not ask the user if they want to install anyway.
