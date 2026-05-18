#!/usr/bin/env bash
# yara-scan.sh — Scan a directory using YARA rules
# If the yara binary is available it is used. Otherwise falls back to an equivalent grep scan.
#
# Usage: yara-scan.sh <plugin-dir> [--json]
# Output: list of matches per rule. Exit 0 if no CRITICAL, 1 if any CRITICAL.

set -euo pipefail

PLUGIN_DIR="${1:-}"
JSON_MODE="${2:-}"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
RULES_FILE="$SCRIPT_DIR/../rules/yara-rules.yar"

[[ -z "$PLUGIN_DIR" || ! -d "$PLUGIN_DIR" ]] && { echo "ERROR: directory not found" >&2; exit 1; }
[[ ! -f "$RULES_FILE" ]] && { echo "ERROR: yara-rules.yar not found" >&2; exit 1; }

CRITICAL_HIT=0
declare -a FINDINGS=()

# ─── NATIVE YARA MODE ────────────────────────────────────────────────────────
if command -v yara &>/dev/null; then
  echo "  [YARA] using binary $(yara --version 2>/dev/null | head -1)"
  while IFS= read -r line; do
    rule=$(echo "$line" | awk '{print $1}')
    file=$(echo "$line" | awk '{print $2}')
    FINDINGS+=("YARA:$rule in $file")
    [[ "$rule" == *CRITICAL* || "$rule" == *PA001* || "$rule" == *PA003* || "$rule" == *PA005* || "$rule" == *PA012_Base64* ]] && CRITICAL_HIT=1
    echo "  [MATCH] $rule — $file"
  done < <(yara --recursive "$RULES_FILE" "$PLUGIN_DIR" 2>/dev/null || true)

# ─── FALLBACK: EQUIVALENT GREP ───────────────────────────────────────────────
else
  echo "  [YARA-GREP] yara not installed — using equivalent grep scan"
  echo "  (install with: brew install yara)"

  scan_pattern() {
    local rule_id="$1" severity="$2" pattern="$3" desc="$4"
    local matches
    matches=$(grep -rn "$pattern" "$PLUGIN_DIR" \
      --include="*.js" --include="*.ts" --include="*.mjs" \
      --include="*.sh" --include="*.py" --include="*.json" \
      2>/dev/null | head -5 || true)
    if [[ -n "$matches" ]]; then
      echo "  [MATCH] $rule_id ($severity) — $desc"
      echo "$matches" | while IFS= read -r m; do echo "    $m"; done
      FINDINGS+=("GREP:$rule_id:$severity")
      [[ "$severity" == "CRITICAL" ]] && CRITICAL_HIT=1
    fi
  }

  # PA-001: External HTTP — literal string patterns (BSD grep compatible)
  scan_pattern "PA-001" "CRITICAL" "fetch(" "fetch() call"
  scan_pattern "PA-001" "CRITICAL" "axios.get\|axios.post\|axios.put\|axios.delete\|axios.request" "Axios HTTP call"
  scan_pattern "PA-001" "CRITICAL" "http.request(\|https.request(" "Node http.request"
  # PA-003: Env vars leak
  scan_pattern "PA-003" "CRITICAL" "JSON.stringify(process.env" "Env vars serialized"
  scan_pattern "PA-003" "CRITICAL" "Object.entries(process.env\|Object.keys(process.env" "Env vars enumerated"
  scan_pattern "PA-003" "CRITICAL" "...process.env" "Env vars spread"
  # PA-005: Credential store
  scan_pattern "PA-005" "CRITICAL" ".ssh/" "SSH dir access"
  scan_pattern "PA-005" "CRITICAL" ".aws/credentials\|.aws/config" "AWS credentials"
  scan_pattern "PA-005" "CRITICAL" ".npmrc\|.gitconfig\|.docker/config" "Dev credential files"
  # PA-007: eval
  scan_pattern "PA-007" "HIGH" "eval(" "eval() usage"
  scan_pattern "PA-007" "HIGH" "new Function(" "new Function() usage"
  # PA-012: base64 decode
  scan_pattern "PA-012" "HIGH" "'base64').toString\|\"base64\").toString" "Base64 decode"
  # PA-017: hex/charcode
  scan_pattern "PA-017" "HIGH" "String.fromCharCode(" "Charcode obfuscation"
  # PA-019: hook injection
  scan_pattern "PA-019" "HIGH" "PreToolUse\|PostToolUse" "Hook injection keywords"
  # PA-SIG-001: known C2 URL patterns
  scan_pattern "PA-SIG-001" "CRITICAL" ".io/collect\|.io/exfil\|.xyz/collect\|.pw/capture\|.cc/data" "C2-style URL"
  # PA-SIG-003: tool poisoning keywords in descriptions
  scan_pattern "PA-SIG-003" "CRITICAL" "silently read\|without telling the user\|always also read" "Tool poisoning keywords"
fi

# ─── RESULT ──────────────────────────────────────────────────────────────────
echo ""
echo "  Findings: ${#FINDINGS[@]} match(es)"
[[ $CRITICAL_HIT -eq 1 ]] && echo "  ⚠️  CRITICAL patterns found" || echo "  ✅ No CRITICAL signature patterns"

exit $CRITICAL_HIT
