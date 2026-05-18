#!/usr/bin/env node
/**
 * audit-to-sarif.js — Convert audit cache JSON to SARIF 2.1.0 format.
 *
 * Usage:
 *   node audit-to-sarif.js <cache.json> [output.sarif.json]
 *   node audit-to-sarif.js <plugin-dir>
 *
 * SARIF is the standard format (GitHub Code Scanning, VS Code, Azure DevOps)
 * for reporting security findings as PR annotations.
 */

'use strict';

const fs = require('fs');
const path = require('path');
const { execSync } = require('child_process');

const HOME = process.env.HOME;
const CACHE_DIR = path.join(HOME, '.claude', 'audit-cache');

// PA-XXX rule metadata for SARIF output
const RULE_METADATA = {
  'PA-001': { name: 'ExternalHTTPExfiltration',    severity: 'error',   tags: ['security', 'exfiltration'] },
  'PA-002': { name: 'WebSocketExternalConnection', severity: 'error',   tags: ['security', 'exfiltration'] },
  'PA-003': { name: 'EnvironmentVariablesLeak',    severity: 'error',   tags: ['security', 'exfiltration'] },
  'PA-004': { name: 'DotenvFileAccess',            severity: 'warning', tags: ['security', 'sensitive-data'] },
  'PA-005': { name: 'CredentialStoreAccess',       severity: 'error',   tags: ['security', 'sensitive-data'] },
  'PA-006': { name: 'OutOfScopeFileRead',          severity: 'warning', tags: ['security', 'sensitive-data'] },
  'PA-007': { name: 'DynamicCodeEvaluation',       severity: 'warning', tags: ['security', 'hidden-execution'] },
  'PA-008': { name: 'ShellCommandExecution',       severity: 'warning', tags: ['security', 'hidden-execution'] },
  'PA-009': { name: 'DynamicImportWithVariable',   severity: 'note',    tags: ['security', 'hidden-execution'] },
  'PA-010': { name: 'PackageLifecycleScripts',     severity: 'error',   tags: ['security', 'supply-chain'] },
  'PA-011': { name: 'MinifiedExecutableCode',      severity: 'note',    tags: ['security', 'obfuscation'] },
  'PA-012': { name: 'Base64EncodedCommands',       severity: 'error',   tags: ['security', 'obfuscation'] },
  'PA-014': { name: 'PermissionScopeMismatch',     severity: 'warning', tags: ['security', 'permissions'] },
  'PA-015': { name: 'MarkdownPromptInjection',     severity: 'error',   tags: ['security', 'prompt-injection'] },
  'PA-016': { name: 'HiddenInstructionInjection',  severity: 'error',   tags: ['security', 'prompt-injection'] },
  'PA-017': { name: 'HexCharcodeObfuscation',      severity: 'error',   tags: ['security', 'obfuscation'] },
  'PA-018': { name: 'MCPParamsExfiltration',       severity: 'error',   tags: ['security', 'exfiltration'] },
  'PA-019': { name: 'ClaudeCodeHookInjection',     severity: 'warning', tags: ['security', 'hidden-execution'] },
  'PA-020': { name: 'UnversionedPackageExecution', severity: 'warning', tags: ['security', 'supply-chain'] },
  'PA-021': { name: 'DependencyRedFlags',          severity: 'warning', tags: ['security', 'supply-chain'] },
  'PA-022': { name: 'ShellCommandInjection',       severity: 'warning', tags: ['security', 'hidden-execution'] },
  'PA-023': { name: 'ToolPoisoningSemantic',       severity: 'error',   tags: ['security', 'prompt-injection'] },
  'PA-024': { name: 'KnownVulnerableDependency',   severity: 'warning', tags: ['security', 'supply-chain'] },
};

function verdictToLevel(verdict) {
  switch (verdict) {
    case 'DO_NOT_INSTALL': return 'error';
    case 'REVIEW':         return 'warning';
    case 'SAFE_WITH_CODE': return 'note';
    case 'SAFE':           return 'none';
    default:               return 'warning';
  }
}

function buildSarif(auditData) {
  const rulesTriggered = auditData.rules_triggered || [];
  const pluginName = auditData.plugin || 'unknown';
  const verdict = auditData.verdict || 'UNKNOWN';

  // Build rules array from triggered rules
  const rules = rulesTriggered.map(ruleId => {
    const meta = RULE_METADATA[ruleId] || { name: ruleId, severity: 'warning', tags: ['security'] };
    return {
      id: ruleId,
      name: meta.name,
      shortDescription: { text: `${ruleId}: ${meta.name}` },
      fullDescription: { text: `Plugin security rule ${ruleId} triggered in ${pluginName}` },
      defaultConfiguration: { level: meta.severity },
      properties: { tags: meta.tags, 'security-severity': meta.severity === 'error' ? '9.0' : '6.0' }
    };
  });

  // Build results (one per triggered rule — without file:line since cache doesn't store them)
  const results = rulesTriggered.map(ruleId => {
    const meta = RULE_METADATA[ruleId] || { name: ruleId, severity: 'warning', tags: [] };
    return {
      ruleId,
      level: meta.severity,
      message: {
        text: `${ruleId} (${meta.name}) triggered in plugin "${pluginName}". Verdict: ${verdict}. Audited: ${auditData.audited_at || 'unknown'}.`
      },
      locations: [{
        physicalLocation: {
          artifactLocation: { uri: pluginName, uriBaseId: 'PLUGIN_ROOT' }
        }
      }]
    };
  });

  // Summary result for overall verdict
  if (results.length === 0) {
    results.push({
      ruleId: 'PLUGIN-AUDIT',
      level: verdictToLevel(verdict),
      message: { text: `Plugin "${pluginName}" audited. Verdict: ${verdict}. No specific rules triggered.` },
      locations: [{ physicalLocation: { artifactLocation: { uri: pluginName, uriBaseId: 'PLUGIN_ROOT' } } }]
    });
  }

  return {
    '$schema': 'https://raw.githubusercontent.com/oasis-tcs/sarif-spec/master/Schemata/sarif-schema-2.1.0.json',
    version: '2.1.0',
    runs: [{
      tool: {
        driver: {
          name: 'kenaz',
          version: '1.1.0',
          informationUri: 'https://github.com/devgard-labs/kenaz',
          rules: rules.length > 0 ? rules : [{ id: 'PLUGIN-AUDIT', name: 'PluginAuditVerdict', shortDescription: { text: 'Overall plugin audit verdict' } }]
        }
      },
      results,
      invocations: [{
        executionSuccessful: true,
        commandLine: `kenaz audit ${pluginName}`
      }]
    }]
  };
}

function findCacheFile(arg) {
  // If arg is a direct JSON file
  if (fs.existsSync(arg) && arg.endsWith('.json')) return arg;

  // If arg is a plugin directory, find its cache entry
  const pluginName = path.basename(arg.replace(/\/$/, ''));
  try {
    const files = fs.readdirSync(CACHE_DIR);
    const hit = files.find(f => f.startsWith(`${pluginName}_`) && f.endsWith('.json'));
    if (hit) return path.join(CACHE_DIR, hit);
  } catch { /* cache dir may not exist */ }

  return null;
}

// ── Main ──────────────────────────────────────────────────────────────────────
const arg = process.argv[2];
const outputArg = process.argv[3];

if (!arg) {
  console.error('Usage: audit-to-sarif.js <cache.json|plugin-dir> [output.sarif.json]');
  process.exit(1);
}

const cacheFile = findCacheFile(arg);
if (!cacheFile) {
  console.error(`ERROR: no cache entry found for "${arg}". Run /kenaz first.`);
  process.exit(1);
}

const auditData = JSON.parse(fs.readFileSync(cacheFile, 'utf8'));
const sarif = buildSarif(auditData);
const sarifJson = JSON.stringify(sarif, null, 2);

if (outputArg) {
  fs.writeFileSync(outputArg, sarifJson);
  console.log(`SARIF written to: ${outputArg}`);
} else {
  console.log(sarifJson);
}
