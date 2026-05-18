#!/usr/bin/env bash
# plugin-inventory.sh — Inventory of installed plugins/MCPs with SHA-256 hashes.
#
# Commands:
#   plugin-inventory.sh --register <plugin-dir> <verdict>  Register plugin with hash
#   plugin-inventory.sh --list                              List inventory
#   plugin-inventory.sh --check                             Detect changes (rug pulls)
#   plugin-inventory.sh --check-mcps                        Check MCP configs across IDEs
#   plugin-inventory.sh --unregister <plugin-name>          Remove from inventory
#
# Inventory file: ~/.claude/audit-inventory.json

set -euo pipefail

INVENTORY="$HOME/.claude/audit-inventory.json"
AUDIT_CACHE_DIR="$HOME/.claude/audit-cache"

# MCP config locations to monitor
MCP_CONFIGS=(
  "$HOME/Library/Application Support/Claude/claude_desktop_config.json"
  "$HOME/.cursor/mcp.json"
  "$HOME/.config/windsurf/mcp.json"
  "$HOME/.claude/settings.json"
)

_init_inventory() {
  if [[ ! -f "$INVENTORY" ]]; then
    echo '{"version": 1, "plugins": [], "mcp_hashes": {}}' > "$INVENTORY"
  fi
}

_sha_dir() {
  local dir="$1"
  find "$dir" -type f \
    ! -name "expected.json" \
    ! -path "*/node_modules/*" \
    ! -path "*/.git/*" \
    | sort | xargs sha256sum 2>/dev/null | sha256sum | awk '{print $1}'
}

_sha_file() {
  sha256sum "$1" 2>/dev/null | awk '{print $1}'
}

cmd_register() {
  local plugin_dir="${1:-}"
  local verdict="${2:-UNKNOWN}"
  [[ -z "$plugin_dir" || ! -d "$plugin_dir" ]] && { echo "ERROR: directory not found: $plugin_dir" >&2; exit 1; }

  _init_inventory
  local name
  name=$(basename "$plugin_dir")
  local hash
  hash=$(_sha_dir "$plugin_dir")
  local now
  now=$(date -u +"%Y-%m-%dT%H:%M:%SZ")
  local version="unknown"
  local pjson="$plugin_dir/plugin.json"
  [[ -f "$pjson" ]] && version=$(python3 -c "import json; d=json.load(open('$pjson')); print(d.get('version','unknown'))" 2>/dev/null || echo "unknown")

  # Remove existing entry if any, then add new one
  python3 - "$INVENTORY" "$name" "$plugin_dir" "$hash" "$verdict" "$now" "$version" <<'EOF'
import json, sys
inventory_path, name, path, hash_, verdict, now, version = sys.argv[1:]
with open(inventory_path) as f:
    inv = json.load(f)
inv["plugins"] = [p for p in inv["plugins"] if p["name"] != name]
inv["plugins"].append({
    "name": name,
    "path": path,
    "version": version,
    "sha256": hash_,
    "verdict": verdict,
    "registered_at": now,
    "last_checked": now,
    "status": "ok"
})
with open(inventory_path, "w") as f:
    json.dump(inv, f, indent=2)
print(f"  REGISTERED  {name} @ {version}  verdict={verdict}  sha={hash_[:16]}")
EOF
}

cmd_unregister() {
  local name="${1:-}"
  [[ -z "$name" ]] && { echo "ERROR: plugin name required" >&2; exit 1; }
  _init_inventory
  python3 - "$INVENTORY" "$name" <<'EOF'
import json, sys
inventory_path, name = sys.argv[1:]
with open(inventory_path) as f:
    inv = json.load(f)
before = len(inv["plugins"])
inv["plugins"] = [p for p in inv["plugins"] if p["name"] != name]
with open(inventory_path, "w") as f:
    json.dump(inv, f, indent=2)
removed = before - len(inv["plugins"])
print(f"  {'REMOVED' if removed else 'NOT FOUND'}  {name}")
EOF
}

cmd_list() {
  _init_inventory
  echo "=== Plugin Inventory ==="
  python3 - "$INVENTORY" <<'EOF'
import json, sys
with open(sys.argv[1]) as f:
    inv = json.load(f)
plugins = inv.get("plugins", [])
if not plugins:
    print("  (empty)")
else:
    for p in plugins:
        status = p.get("status", "ok")
        flag = "⚠️ CHANGED" if status == "changed" else "✅"
        print(f"  {flag} {p['name']} v{p['version']}  verdict={p['verdict']}  sha={p['sha256'][:16]}  registered={p['registered_at'][:10]}")
mcp = inv.get("mcp_hashes", {})
if mcp:
    print("\n=== MCP Config Hashes ===")
    for path, info in mcp.items():
        status = info.get("status", "ok")
        flag = "⚠️ CHANGED" if status == "changed" else "✅"
        print(f"  {flag} {path}  sha={info['sha256'][:16]}  checked={info['checked_at'][:10]}")
EOF
}

cmd_check() {
  _init_inventory
  local changes=0
  echo "=== Checking plugin integrity ==="
  local now
  now=$(date -u +"%Y-%m-%dT%H:%M:%SZ")

  python3 - "$INVENTORY" "$now" <<'PYEOF'
import json, sys, subprocess, os
inventory_path, now = sys.argv[1:]

with open(inventory_path) as f:
    inv = json.load(f)

changes = 0
for p in inv["plugins"]:
    path = p["path"]
    if not os.path.isdir(path):
        print(f"  ⚠️  MISSING   {p['name']} — directory not found: {path}")
        p["status"] = "missing"
        changes += 1
        continue

    # Compute current hash
    result = subprocess.run(
        ["bash", "-c", f"find {path!r} -type f ! -name expected.json ! -path '*/node_modules/*' ! -path '*/.git/*' | sort | xargs sha256sum 2>/dev/null | sha256sum | awk '{{print $1}}'"],
        capture_output=True, text=True
    )
    current_sha = result.stdout.strip()
    stored_sha = p["sha256"]
    p["last_checked"] = now

    if current_sha != stored_sha:
        print(f"  🚨 CHANGED   {p['name']} — hash changed since last audit")
        print(f"     stored : {stored_sha[:32]}")
        print(f"     current: {current_sha[:32]}")
        print(f"     Action required: /kenaz {path}")
        p["status"] = "changed"
        p["current_sha"] = current_sha
        changes += 1
    else:
        print(f"  ✅ OK        {p['name']} v{p['version']}  (sha={stored_sha[:16]})")
        p["status"] = "ok"

with open(inventory_path, "w") as f:
    json.dump(inv, f, indent=2)

sys.exit(1 if changes > 0 else 0)
PYEOF
  local exit_code=$?
  [[ $exit_code -ne 0 ]] && echo "" && echo "⚠️  $exit_code plugin(s) changed — re-audit before use"
  return $exit_code
}

cmd_check_mcps() {
  _init_inventory
  echo "=== Checking MCP config integrity ==="
  local now
  now=$(date -u +"%Y-%m-%dT%H:%M:%SZ")
  local changes=0

  for config in "${MCP_CONFIGS[@]}"; do
    [[ ! -f "$config" ]] && continue
    local current_sha
    current_sha=$(_sha_file "$config")

    python3 - "$INVENTORY" "$config" "$current_sha" "$now" <<'PYEOF'
import json, sys
inventory_path, config_path, current_sha, now = sys.argv[1:]
with open(inventory_path) as f:
    inv = json.load(f)
if "mcp_hashes" not in inv:
    inv["mcp_hashes"] = {}
stored = inv["mcp_hashes"].get(config_path)
if stored is None:
    inv["mcp_hashes"][config_path] = {"sha256": current_sha, "checked_at": now, "status": "ok"}
    print(f"  REGISTERED  {config_path}  sha={current_sha[:16]}")
elif stored["sha256"] != current_sha:
    print(f"  🚨 CHANGED   {config_path}")
    print(f"     stored : {stored['sha256'][:32]}")
    print(f"     current: {current_sha[:32]}")
    print(f"     Action: review manually or run /kenaz self")
    inv["mcp_hashes"][config_path] = {"sha256": current_sha, "checked_at": now, "status": "changed", "prev_sha": stored["sha256"]}
else:
    print(f"  ✅ OK        {config_path}")
    inv["mcp_hashes"][config_path]["checked_at"] = now
    inv["mcp_hashes"][config_path]["status"] = "ok"
with open(inventory_path, "w") as f:
    json.dump(inv, f, indent=2)
PYEOF
  done
}

# --- Dispatch ---
CMD="${1:-}"
case "$CMD" in
  --register)    cmd_register "${2:-}" "${3:-SAFE}" ;;
  --unregister)  cmd_unregister "${2:-}" ;;
  --list)        cmd_list ;;
  --check)       cmd_check ;;
  --check-mcps)  cmd_check_mcps ;;
  *)
    echo "Usage: plugin-inventory.sh <command>"
    echo "  --register <dir> <verdict>   Register plugin with SHA-256 hash"
    echo "  --unregister <name>          Remove from inventory"
    echo "  --list                       Show inventory"
    echo "  --check                      Detect changes in registered plugins"
    echo "  --check-mcps                 Detect changes in IDE MCP configs"
    exit 1
    ;;
esac
