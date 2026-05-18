#!/usr/bin/env bash
# ci-audit.sh — CI mode for Kenaz.
# Usage: ci-audit.sh <plugin-dir> [--json]
# Exit code: 0 = SAFE/SAFE_WITH_CODE/REVIEW, 1 = DO_NOT_INSTALL, 2 = error
# In CI: add as a pipeline step before installing any plugin.

set -euo pipefail

PLUGIN_DIR="${1:?Usage: ci-audit.sh <plugin-dir> [--json]}"
JSON_MODE="${2:-}"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
CACHE_SCRIPT="$SCRIPT_DIR/audit-cache.sh"

if [[ ! -d "$PLUGIN_DIR" ]]; then
  echo "ERROR: plugin directory not found: $PLUGIN_DIR" >&2
  exit 2
fi

# 1. Check cache first
if [[ -x "$CACHE_SCRIPT" ]]; then
  CACHE_OUT=$("$CACHE_SCRIPT" "$PLUGIN_DIR" 2>/dev/null || true)
  if echo "$CACHE_OUT" | grep -q "^HIT"; then
    CACHE_FILE=$(echo "$CACHE_OUT" | grep "^HIT" | awk '{print $2}')
    VERDICT=$(python3 -c "import json,sys; d=json.load(open('$CACHE_FILE')); print(d['verdict'])" 2>/dev/null || echo "")
    if [[ -n "$VERDICT" ]]; then
      echo "CACHE HIT — skipping re-audit (hash unchanged)"
      echo "VERDICT: $VERDICT"
      [[ "$VERDICT" == "DO_NOT_INSTALL" ]] && exit 1
      exit 0
    fi
  fi
fi

# 2. Invoke the auditor via the claude CLI
PROMPT="Audit the plugin at: $PLUGIN_DIR
Respond with ONLY this final line after your analysis:
VERDICT: SAFE | VERDICT: SAFE_WITH_CODE | VERDICT: REVIEW | VERDICT: DO_NOT_INSTALL
Also include: RULES: [comma-separated PA-XXX IDs or none]"

echo "Auditing: $PLUGIN_DIR"
OUTPUT=$(claude -p "$PROMPT" 2>&1) || {
  echo "ERROR: claude CLI failed. Is claude installed and authenticated?" >&2
  exit 2
}

# 3. Extract verdict
VERDICT=$(echo "$OUTPUT" | grep "^VERDICT:" | tail -1 | sed 's/VERDICT: //')
RULES=$(echo "$OUTPUT" | grep "^RULES:" | tail -1 | sed 's/RULES: //' || echo "[]")

if [[ -z "$VERDICT" ]]; then
  echo "ERROR: could not parse verdict from audit output" >&2
  echo "$OUTPUT" >&2
  exit 2
fi

# 4. Save to cache
if [[ -x "$CACHE_SCRIPT" ]]; then
  "$CACHE_SCRIPT" "$PLUGIN_DIR" --write "$VERDICT" "$RULES" > /dev/null 2>&1 || true
fi

# 5. Output and exit code
echo "VERDICT: $VERDICT"
[[ -n "$RULES" ]] && echo "RULES: $RULES"

if [[ "$VERDICT" == "DO_NOT_INSTALL" ]]; then
  echo "BLOCKED — plugin must not be installed" >&2
  exit 1
fi

exit 0
