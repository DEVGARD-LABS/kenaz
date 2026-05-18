#!/usr/bin/env bash
# audit-cache.sh — Audit cache keyed by SHA-256 of the plugin directory.
# Usage: audit-cache.sh <plugin-dir> [--write <verdict> <rules>]
# Returns: "HIT <cache-file>" or "MISS <cache-file-path>"

set -euo pipefail

PLUGIN_DIR="${1:?Usage: audit-cache.sh <plugin-dir> [--write <verdict> <rules>]}"
CACHE_DIR="$HOME/.claude/audit-cache"
mkdir -p "$CACHE_DIR"

# Reproducible hash of plugin contents (excludes non-functional metadata)
HASH=$(find "$PLUGIN_DIR" -type f \
  ! -name "expected.json" \
  ! -name "*.json.bak" \
  ! -path "*/node_modules/*" \
  ! -path "*/.git/*" \
  ! -path "*/.claude-plugin/*" \
  | sort \
  | xargs sha256sum 2>/dev/null \
  | sha256sum \
  | awk '{print $1}')

PLUGIN_NAME="$(basename "$PLUGIN_DIR")"
CACHE_FILE="$CACHE_DIR/${PLUGIN_NAME}_${HASH:0:16}.json"

# Write mode: --write <verdict> <rules>
if [[ "${2:-}" == "--write" ]]; then
  VERDICT="${3:?--write requires <verdict>}"
  RULES="${4:-[]}"
  cat > "$CACHE_FILE" <<JSON
{
  "plugin": "$PLUGIN_NAME",
  "hash": "$HASH",
  "verdict": "$VERDICT",
  "rules_triggered": $RULES,
  "audited_at": "$(date -u +%Y-%m-%dT%H:%M:%SZ)"
}
JSON
  echo "WRITTEN $CACHE_FILE"
  exit 0
fi

# Read mode
if [[ -f "$CACHE_FILE" ]]; then
  echo "HIT $CACHE_FILE"
  cat "$CACHE_FILE"
  exit 0
fi

echo "MISS $CACHE_FILE"
exit 1
