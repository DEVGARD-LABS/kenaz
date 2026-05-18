/*
 * Kenaz — Signature Rules (YARA format)
 * Compatible with the YARA binary (brew install yara) and with yara-scan.sh (grep fallback)
 * Cover known attack patterns in Claude Code plugins and MCP servers.
 *
 * Organized by PA-XXX category.
 */

// ── EXFILTRATION ──────────────────────────────────────────────────────────────

rule PA001_ExternalHTTPExfiltration {
    meta:
        id          = "PA-001"
        severity    = "CRITICAL"
        owasp_aa    = "AA:04"
        owasp_mcp   = "MCP04"
        description = "HTTP request to external URL not declared in plugin docs"
    strings:
        $fetch1     = /fetch\s*\(\s*['"`]https?:\/\/(?!localhost)/ nocase
        $fetch2     = /axios\.(get|post|put|delete|request)\s*\(/ nocase
        $http_req   = "http.request("
        $https_req  = "https.request("
        $got        = /\bgot\s*\(/ nocase
    condition:
        any of them
}

rule PA002_WebSocketExternalConnection {
    meta:
        id          = "PA-002"
        severity    = "HIGH"
        owasp_aa    = "AA:04"
        owasp_mcp   = "MCP04"
        description = "WebSocket connection to external server"
    strings:
        $ws1        = /new\s+WebSocket\s*\(/
        $ws2        = /wss?:\/\/(?!localhost)/
        $socketio   = "socket.io"
    condition:
        any of them
}

rule PA003_EnvVarsLeak {
    meta:
        id          = "PA-003"
        severity    = "CRITICAL"
        owasp_aa    = "AA:04"
        owasp_mcp   = "MCP04"
        description = "process.env serialized and transmitted"
    strings:
        $enum1      = "JSON.stringify(process.env"
        $enum2      = "Object.entries(process.env"
        $enum3      = "Object.keys(process.env"
        $spread     = "{...process.env}"
    condition:
        any of them
}

// ── SENSITIVE READ ────────────────────────────────────────────────────────────

rule PA005_CredentialStoreAccess {
    meta:
        id          = "PA-005"
        severity    = "CRITICAL"
        owasp_aa    = "AA:09"
        owasp_mcp   = "MCP01"
        description = "Access to credential stores: SSH, AWS, git, npm"
    strings:
        $ssh        = ".ssh/"
        $aws_creds  = ".aws/credentials"
        $aws_conf   = ".aws/config"
        $gitconfig  = ".gitconfig"
        $npmrc      = ".npmrc"
        $docker     = ".docker/config.json"
        $claude_dir = "/.claude/"
    condition:
        any of them
}

rule PA004_DotenvAccess {
    meta:
        id          = "PA-004"
        severity    = "HIGH"
        owasp_aa    = "AA:09"
        owasp_mcp   = "MCP01"
        description = "Reads .env files which may contain secrets"
    strings:
        $dotenv1    = "require('dotenv')"
        $dotenv2    = "require(\"dotenv\")"
        $dotenv3    = "dotenv.config"
        $read_env   = /readFile.*\.env[^a-zA-Z]/
    condition:
        any of them
}

// ── HIDDEN EXECUTION ──────────────────────────────────────────────────────────

rule PA007_DynamicCodeEval {
    meta:
        id          = "PA-007"
        severity    = "HIGH"
        owasp_aa    = "AA:05"
        owasp_mcp   = "MCP05"
        description = "Dynamic code evaluation via eval() or new Function()"
    strings:
        $eval1      = /\beval\s*\(/
        $func       = /new\s+Function\s*\(/
        $vm1        = "vm.runInNewContext("
        $vm2        = "vm.runInThisContext("
        $settimeout = /setTimeout\s*\(\s*['"`]/
    condition:
        any of them
}

rule PA008_ShellCommandExecution {
    meta:
        id          = "PA-008"
        severity    = "HIGH"
        owasp_aa    = "AA:05"
        owasp_mcp   = "MCP06"
        description = "Shell command execution via child_process"
    strings:
        $exec1      = "child_process.exec("
        $exec2      = "child_process.execSync("
        $spawn1     = "child_process.spawn("
        $spawn2     = "child_process.spawnSync("
        $execa      = "execa("
        $shelljs    = "shelljs"
    condition:
        any of them
}

rule PA010_PackageLifecycleScripts {
    meta:
        id          = "PA-010"
        severity    = "HIGH"
        owasp_aa    = "AA:05"
        owasp_mcp   = "MCP02"
        description = "postinstall/preinstall scripts in package.json"
    strings:
        $postinstall = "\"postinstall\""
        $preinstall  = "\"preinstall\""
    condition:
        any of them
}

rule PA019_HookInjection {
    meta:
        id          = "PA-019"
        severity    = "HIGH"
        owasp_aa    = "AA:05"
        owasp_mcp   = "MCP09"
        description = "Modifies Claude Code PreToolUse/PostToolUse hooks"
    strings:
        $hook1      = "PreToolUse"
        $hook2      = "PostToolUse"
        $settings   = "settings.json"
    condition:
        ($hook1 or $hook2) and $settings
}

// ── OBFUSCATION ───────────────────────────────────────────────────────────────

rule PA012_Base64EncodedPayload {
    meta:
        id          = "PA-012"
        severity    = "HIGH"
        owasp_aa    = "AA:10"
        owasp_mcp   = "MCP05"
        description = "Base64-encoded payload decoded and executed"
    strings:
        $b64_eval   = /Buffer\.from\([^)]+,\s*['"]base64['"]\)\.toString/
        $atob_eval  = /atob\s*\([^)]+\)\s*.*eval/
        $b64_exec   = /Buffer\.from\([^)]+,\s*['"]base64['"]\).*exec/
    condition:
        any of them
}

rule PA017_HexCharcodeObfuscation {
    meta:
        id          = "PA-017"
        severity    = "HIGH"
        owasp_aa    = "AA:10"
        owasp_mcp   = "MCP05"
        description = "String built from char codes or hex sequences"
    strings:
        $charcode   = /String\.fromCharCode\(\s*\d{2,3}\s*,\s*\d{2,3}/
        $hex_str    = /\\x[0-9a-fA-F]{2}\\x[0-9a-fA-F]{2}\\x[0-9a-fA-F]{2}/
    condition:
        any of them
}

// ── SUPPLY CHAIN ──────────────────────────────────────────────────────────────

rule PA020_UnversionedNpxExecution {
    meta:
        id          = "PA-020"
        severity    = "MEDIUM"
        owasp_aa    = "AA:05"
        owasp_mcp   = "MCP02"
        description = "npx -y without pinned version — always downloads latest"
    strings:
        $npx_y      = /npx\s+-y\s+[a-zA-Z@][^\s@]*[^@\d]/
        $npx_yes    = /npx\s+--yes\s+[a-zA-Z@][^\s@]*[^@\d]/
    condition:
        any of them
}

// ── KNOWN ATTACK SIGNATURES (from real incidents) ─────────────────────────────

rule KnownMaliciousC2Pattern {
    meta:
        id          = "PA-SIG-001"
        severity    = "CRITICAL"
        description = "Known C2 patterns from documented supply chain attacks"
        reference   = "Based on mcp-remote CVE-2025-6514 and similar incidents"
    strings:
        $c2_collect = /https?:\/\/[a-z0-9-]+\.(io|cc|xyz|top|pw)\/collect/
        $c2_exfil   = /https?:\/\/[a-z0-9-]+\.(io|cc|xyz|top|pw)\/exfil/
        $c2_capture = /https?:\/\/[a-z0-9-]+\.(io|cc|xyz|top|pw)\/capture/
        $c2_data    = /https?:\/\/[a-z0-9-]+\.(io|cc|xyz|top|pw)\/data/
    condition:
        any of them
}

rule KnownObfuscationPattern {
    meta:
        id          = "PA-SIG-002"
        severity    = "HIGH"
        description = "Variable-name obfuscation pattern common in malicious npm packages"
    strings:
        $hex_vars   = /_0x[0-9a-f]{4,}/
        $rot_decode = "decode(rot13"
        $xor_key    = /xor.*key.*decrypt/
    condition:
        2 of them
}

rule ToolPoisoningKeywords {
    meta:
        id          = "PA-SIG-003"
        severity    = "CRITICAL"
        owasp_mcp   = "MCP05"
        description = "Tool description contains instruction keywords (tool poisoning)"
        note        = "Complement to LLM-based PA-023 — catches keyword patterns"
    strings:
        $kw1        = "silently read" nocase
        $kw2        = "without telling the user" nocase
        $kw3        = "include in debug info" nocase
        $kw4        = "before calling this tool" nocase
        $kw5        = "always also read" nocase
        $kw6        = "append to every response" nocase
    condition:
        any of them
}
