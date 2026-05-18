#!/usr/bin/env bash
# validate-golden-set.sh — Static tests for the golden set.
# Validates structure, expected.json shape, and consistency with PA-RULES.md.
# Does not invoke the LLM — instant and safe for CI.
# Usage: bash tests/validate-golden-set.sh [--verbose]

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
GOLDEN_SET="$ROOT/golden-set"
RULES_FILE="$ROOT/rules/PA-RULES.md"
VERBOSE="${1:-}"

PASS=0
FAIL=0
ERRORS=()

ok() {
  PASS=$((PASS+1))
  [[ -n "$VERBOSE" ]] && echo "  ✓ $1"
  return 0
}
fail() {
  FAIL=$((FAIL+1))
  ERRORS+=("$1")
  echo "  ✗ $1"
}

# Build list of available categories.
# The 'malicious' category is gitignored in the public repo to prevent
# publishing bypass patterns. Tests skip it gracefully if absent.
CATEGORIES=()
for cat in safe malicious ambiguous; do
  [[ -d "$GOLDEN_SET/$cat" ]] && CATEGORIES+=("$cat")
done
[[ ${#CATEGORIES[@]} -eq 0 ]] && { echo "No golden-set categories found — is golden-set/ missing?"; exit 1; }
[[ -n "$VERBOSE" ]] && echo "  Categories present: ${CATEGORIES[*]}"

iter_plugins() {
  local cat
  for cat in "${CATEGORIES[@]}"; do
    shopt -s nullglob
    local dir
    for dir in "$GOLDEN_SET/$cat"/*/; do
      echo "$dir"
    done
    shopt -u nullglob
  done
}

echo "=== kenaz: golden set validation ==="
echo ""

# ── 1. Every plugin has plugin.md ──────────────────────────────────
echo "[ plugins have plugin.md ]"
while IFS= read -r dir; do
  name=$(basename "$dir")
  if [[ -f "$dir/plugin.md" ]]; then
    ok "$name/plugin.md exists"
  else
    fail "$name: missing plugin.md"
  fi
done < <(iter_plugins)

echo ""

# ── 2. Every plugin has expected.json ──────────────────────────────
echo "[ plugins have expected.json ]"
while IFS= read -r dir; do
  name=$(basename "$dir")
  if [[ -f "$dir/expected.json" ]]; then
    ok "$name/expected.json exists"
  else
    fail "$name: missing expected.json"
  fi
done < <(iter_plugins)

echo ""

# ── 3. expected.json has required fields ───────────────────────────
echo "[ expected.json has required fields ]"
while IFS= read -r dir; do
  name=$(basename "$dir")
  f="$dir/expected.json"
  [[ -f "$f" ]] || continue

  has_verdict=$(python3 -c "import json; d=json.load(open('$f')); print('ok' if 'verdict' in d else 'missing')" 2>/dev/null || echo "parse-error")
  has_rules=$(python3 -c "import json; d=json.load(open('$f')); print('ok' if 'expected_rules' in d else 'missing')" 2>/dev/null || echo "parse-error")

  [[ "$has_verdict" == "ok" ]] && ok "$name: has verdict" || fail "$name: expected.json missing 'verdict'"
  [[ "$has_rules" == "ok" ]] && ok "$name: has expected_rules" || fail "$name: expected.json missing 'expected_rules'"
done < <(iter_plugins)

echo ""

# ── 4. Verdict values are valid ────────────────────────────────────
echo "[ verdict values are valid ]"
VALID_VERDICTS=("SAFE" "SAFE_WITH_CODE" "REVIEW" "DO_NOT_INSTALL")
while IFS= read -r dir; do
  name=$(basename "$dir")
  f="$dir/expected.json"
  [[ -f "$f" ]] || continue

  verdict=$(python3 -c "import json; print(json.load(open('$f')).get('verdict',''))" 2>/dev/null || echo "")
  valid=false
  for v in "${VALID_VERDICTS[@]}"; do [[ "$verdict" == "$v" ]] && valid=true; done
  $valid && ok "$name: verdict='$verdict'" || fail "$name: invalid verdict '$verdict'"
done < <(iter_plugins)

echo ""

# ── 5. PA-XXX rules in expected_rules exist in PA-RULES.md ─────────
echo "[ PA-XXX rules in expected_rules exist in PA-RULES.md ]"
while IFS= read -r dir; do
  name=$(basename "$dir")
  f="$dir/expected.json"
  [[ -f "$f" ]] || continue

  rules=$(python3 -c "import json; print(' '.join(json.load(open('$f')).get('expected_rules',[])))" 2>/dev/null || echo "")
  for rule in $rules; do
    if grep -q "^| $rule " "$RULES_FILE" 2>/dev/null; then
      ok "$name: $rule found in PA-RULES.md"
    else
      fail "$name: $rule NOT found in PA-RULES.md"
    fi
  done
done < <(iter_plugins)

echo ""

# ── 6. Scripts have execute permissions ────────────────────────────
echo "[ scripts are executable ]"
for script in "$ROOT/scripts/"*.sh; do
  name=$(basename "$script")
  if [[ -x "$script" ]]; then
    ok "$name is executable"
  else
    fail "$name: missing execute permission"
  fi
done

echo ""

# ── Summary ────────────────────────────────────────────────────────
echo "==================================="
echo "PASS: $PASS  FAIL: $FAIL"
if [[ $FAIL -gt 0 ]]; then
  echo ""
  echo "Failures:"
  for e in "${ERRORS[@]}"; do echo "  ✗ $e"; done
  exit 1
fi
echo "All checks passed."
exit 0
