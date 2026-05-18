#!/usr/bin/env bash
# Kenaz install.sh — wires Kenaz into ~/.claude
# Usage: bash scripts/install.sh
# Idempotent: safe to run multiple times.

set -euo pipefail

KENAZ_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
CLAUDE_DIR="$HOME/.claude"
VERSION="$(python3 -c "import json; print(json.load(open('$KENAZ_DIR/plugin.json'))['version'])" 2>/dev/null || echo "unknown")"

echo "⚡ Kenaz v$VERSION — installing into $CLAUDE_DIR"
echo ""

# ── Agents ───────────────────────────────────────────────────────────────────
mkdir -p "$CLAUDE_DIR/agents"

ln -sf "$KENAZ_DIR/agents/kenaz.md"  "$CLAUDE_DIR/agents/kenaz.md"
echo "  ✓ @kenaz              → kenaz-plugin/agents/kenaz.md"

ln -sf "$KENAZ_DIR/agents/kenaz.md"  "$CLAUDE_DIR/agents/auditor-plugins.md"
echo "  ✓ @auditor-plugins    → kenaz (backward compat)"

# ── Commands ─────────────────────────────────────────────────────────────────
mkdir -p "$CLAUDE_DIR/commands"

ln -sf "$KENAZ_DIR/commands/kenaz.md"  "$CLAUDE_DIR/commands/kenaz.md"
echo "  ✓ /kenaz              → kenaz-plugin/commands/kenaz.md"

# ── Scripts ──────────────────────────────────────────────────────────────────
mkdir -p "$CLAUDE_DIR/scripts"

ln -sf "$KENAZ_DIR/scripts/audit-cache.sh"       "$CLAUDE_DIR/scripts/audit-cache.sh"
ln -sf "$KENAZ_DIR/scripts/plugin-inventory.sh"  "$CLAUDE_DIR/scripts/plugin-inventory.sh"
chmod +x "$KENAZ_DIR/scripts/audit-cache.sh" "$KENAZ_DIR/scripts/plugin-inventory.sh"
echo "  ✓ Scripts             → kenaz-plugin/scripts/"

# ── Version stamp ─────────────────────────────────────────────────────────────
echo "$VERSION" > "$CLAUDE_DIR/.kenaz-version"
echo "  ✓ Version stamp       $VERSION → $CLAUDE_DIR/.kenaz-version"

echo ""
echo "  Done. Run /kenaz <plugin> to audit."
