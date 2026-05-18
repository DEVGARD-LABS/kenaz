#!/usr/bin/env bash
# Kenaz check-update.sh — SessionStart hook for version check + auto-install
# Runs silently. Never blocks Claude Code (always exits 0).
# Notifies via stderr when update is applied or available.

KENAZ_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
CLAUDE_DIR="$HOME/.claude"
VERSION_FILE="$CLAUDE_DIR/.kenaz-version"

# Read versions
LOCAL_VERSION="$(python3 -c "import json; print(json.load(open('$KENAZ_DIR/plugin.json'))['version'])" 2>/dev/null || echo "")"
INSTALLED_VERSION="$(cat "$VERSION_FILE" 2>/dev/null || echo "")"

# ── Auto-install if local version changed (after git pull) ────────────────────
if [[ -n "$LOCAL_VERSION" && "$LOCAL_VERSION" != "$INSTALLED_VERSION" ]]; then
    bash "$KENAZ_DIR/scripts/install.sh" >/dev/null 2>&1 || true
    echo "⚡ Kenaz updated $INSTALLED_VERSION → $LOCAL_VERSION (auto-installed)" >&2
    exit 0
fi

# ── Check remote for new version (non-blocking, 2s timeout) ──────────────────
if git -C "$KENAZ_DIR" remote get-url origin &>/dev/null; then
    REMOTE_CHECK=$(git -C "$KENAZ_DIR" fetch origin --dry-run 2>&1 || true)
    AHEAD=$(git -C "$KENAZ_DIR" log HEAD..origin/main --oneline 2>/dev/null | wc -l | tr -d ' ')
    if [[ "$AHEAD" -gt 0 ]]; then
        echo "📡 Kenaz: $AHEAD new commit(s) available — run: git pull in kenaz-plugin, changes auto-apply next session" >&2
    fi
fi

exit 0
