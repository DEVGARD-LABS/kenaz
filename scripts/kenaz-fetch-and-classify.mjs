#!/usr/bin/env node
// kenaz-fetch-and-classify.mjs — Cross-platform: macOS, Linux, Windows.
// Clone a GitHub repo (shallow), inventory files, classify the repo type,
// extract a README description. Output: JSON to stdout.
//
// Usage:   node kenaz-fetch-and-classify.mjs <github-url>
// Exit:    0 ok | 1 invalid url | 2 clone failed | 3 empty repo | 4 git missing

import { execFileSync } from 'node:child_process';
import { existsSync, mkdirSync, readdirSync, readFileSync, rmSync, statSync } from 'node:fs';
import { join, basename, dirname, sep } from 'node:path';
import { tmpdir } from 'node:os';

const URL_ARG = process.argv[2];
if (!URL_ARG) {
  process.stderr.write('Usage: node kenaz-fetch-and-classify.mjs <github-url>\n');
  process.exit(1);
}

const URL_REGEX = /^https:\/\/github\.com\/[A-Za-z0-9._-]+\/[A-Za-z0-9._-]+\/?$/;
if (!URL_REGEX.test(URL_ARG)) {
  process.stderr.write(JSON.stringify({ error: 'invalid_url', detail: 'expected https://github.com/<owner>/<repo>' }) + '\n');
  process.exit(1);
}

// Verify git is available
try {
  execFileSync('git', ['--version'], { stdio: 'ignore' });
} catch {
  process.stderr.write(JSON.stringify({ error: 'git_not_found', detail: 'git CLI must be installed and on PATH' }) + '\n');
  process.exit(4);
}

// Normalize URL: strip trailing slash and .git
let url = URL_ARG.replace(/\/$/, '').replace(/\.git$/, '');
const repoName = basename(url);
const owner = basename(dirname(url));

const cloneRoot = join(tmpdir(), 'kenaz-audits');
const cloneDir = join(cloneRoot, `${owner}__${repoName}`);

mkdirSync(cloneRoot, { recursive: true });

// Idempotent: wipe prior clone
if (existsSync(cloneDir)) {
  rmSync(cloneDir, { recursive: true, force: true });
}

try {
  execFileSync('git', ['clone', '--depth', '1', '--quiet', url, cloneDir], { stdio: ['ignore', 'ignore', 'pipe'] });
} catch (e) {
  process.stderr.write(JSON.stringify({ error: 'clone_failed', url, detail: String(e?.message || e).slice(0, 200) }) + '\n');
  process.exit(2);
}

// Drop .git to save space and avoid auditing repo metadata
rmSync(join(cloneDir, '.git'), { recursive: true, force: true });

// --- INVENTORY ---

const SKIP_DIRS = new Set(['node_modules', '.venv', '__pycache__', 'dist', 'build', '.git']);

function walk(dir, files = [], depth = 0) {
  if (depth > 12) return files;
  let entries;
  try { entries = readdirSync(dir, { withFileTypes: true }); } catch { return files; }
  for (const ent of entries) {
    if (ent.name.startsWith('.git') && depth === 0 && ent.name === '.git') continue;
    const full = join(dir, ent.name);
    if (ent.isDirectory()) {
      if (SKIP_DIRS.has(ent.name)) continue;
      walk(full, files, depth + 1);
    } else if (ent.isFile()) {
      files.push(full);
    }
  }
  return files;
}

const allFiles = walk(cloneDir);
const totalFiles = allFiles.length;

if (totalFiles === 0) {
  process.stderr.write(JSON.stringify({ error: 'empty_repo', path: cloneDir }) + '\n');
  process.exit(3);
}

// Total size (bytes → KB)
let totalBytes = 0;
for (const f of allFiles) {
  try { totalBytes += statSync(f).size; } catch {}
}
const totalSizeKb = Math.round(totalBytes / 1024);

// Extension counts
const extCount = {};
for (const f of allFiles) {
  const name = basename(f);
  const dot = name.lastIndexOf('.');
  let ext;
  if (dot <= 0 || dot === name.length - 1) {
    ext = 'noext';
  } else {
    ext = name.slice(dot + 1).toLowerCase();
    if (ext.length > 8) ext = 'noext';
  }
  extCount[ext] = (extCount[ext] || 0) + 1;
}

const c = (ext) => extCount[ext] || 0;

// --- MANIFEST DETECTION ---

const MANIFEST_NAMES = [
  'package.json', 'pyproject.toml', 'setup.py', 'requirements.txt',
  'Cargo.toml', 'go.mod', 'plugin.json', 'mcp.json',
  'composer.json', 'Gemfile', 'pom.xml', 'build.gradle',
];

const manifests = [];
for (const f of allFiles) {
  const rel = f.slice(cloneDir.length + 1).split(sep).join('/');
  const base = basename(rel);
  if (MANIFEST_NAMES.includes(base) || rel === '.claude-plugin/plugin.json') {
    manifests.push(rel);
  }
}

// --- STACK DETECTION ---

const stack = [];
const has = (relPath) => existsSync(join(cloneDir, ...relPath.split('/')));

if (has('package.json')) stack.push('node');
if (has('tsconfig.json') || c('ts') > 0 || c('tsx') > 0) stack.push('typescript');
if (has('pyproject.toml') || has('setup.py') || has('requirements.txt') || c('py') > 0) stack.push('python');
if (has('Cargo.toml') || c('rs') > 0) stack.push('rust');
if (has('go.mod') || c('go') > 0) stack.push('go');
if (has('Gemfile') || c('rb') > 0) stack.push('ruby');
if (c('sh') > 0 || c('bash') > 0) stack.push('shell');
if (c('html') > 0 || c('css') > 0) stack.push('web');

// --- REPO TYPE CLASSIFICATION ---
// First match wins.

let repoType = 'mixed';

function readIfExists(rel) {
  const p = join(cloneDir, ...rel.split('/'));
  if (!existsSync(p)) return '';
  try { return readFileSync(p, 'utf8'); } catch { return ''; }
}

const pkgContent = readIfExists('package.json');
const pyprojectContent = readIfExists('pyproject.toml');
const requirementsContent = readIfExists('requirements.txt');

// Search for MCP markers in manifests/entry points
function hasMcpMarkers() {
  const MCP_REGEX = /modelcontextprotocol|mcp-server|McpServer/i;
  if (MCP_REGEX.test(pkgContent)) return true;
  if (MCP_REGEX.test(pyprojectContent)) return true;
  if (MCP_REGEX.test(requirementsContent)) return true;
  for (const entry of ['server.js', 'server.ts', 'server.mjs', 'server.py']) {
    if (has(entry)) return true;
  }
  return false;
}

const pct = (n) => totalFiles ? Math.round((n * 100) / totalFiles) : 0;

if ((has('plugin.json') || has('.claude-plugin/plugin.json')) &&
    (has('commands') || has('agents') || has('skills'))) {
  repoType = 'plugin-claude-code';
} else if (has('mcp.json') || hasMcpMarkers()) {
  repoType = 'mcp-server';
} else if (pkgContent && /"bin"\s*:/.test(pkgContent)) {
  repoType = 'cli-tool';
} else if (pct(c('md')) > 90) {
  repoType = 'docs';
} else if (
  pct(c('md') + c('txt') + c('mkd') + c('json')) > 70 &&
  c('js') === 0 && c('ts') === 0 && c('py') === 0 && c('sh') === 0 && c('rs') === 0 && c('go') === 0
) {
  repoType = 'dataset';
} else if (has('index.html') || (c('html') > 0 && c('css') > 0)) {
  repoType = 'webapp';
} else if (has('package.json') || has('pyproject.toml') || has('Cargo.toml')) {
  repoType = 'library';
}

// --- README EXTRACTION ---

let description = '';
for (const readme of ['README.md', 'README.MD', 'readme.md', 'Readme.md', 'README.txt', 'README']) {
  const p = join(cloneDir, readme);
  if (existsSync(p)) {
    try {
      const raw = readFileSync(p, 'utf8');
      const lines = raw.split(/\r?\n/)
        .map(l => l.trim())
        .filter(l => l.length > 0 && !l.startsWith('#!'))
        .slice(0, 10);
      description = lines.join(' ').slice(0, 500);
    } catch {}
    break;
  }
}

// --- TOP-LEVEL STRUCTURE ---

const topDirs = [];
try {
  for (const ent of readdirSync(cloneDir, { withFileTypes: true })) {
    if (ent.isDirectory() && !ent.name.startsWith('.')) topDirs.push(ent.name);
    if (topDirs.length >= 20) break;
  }
} catch {}

// --- OUTPUT ---

const output = {
  url,
  owner,
  repo: repoName,
  path: cloneDir,
  total_files: totalFiles,
  total_size_kb: totalSizeKb,
  extensions: extCount,
  manifests,
  stack,
  repo_type: repoType,
  top_dirs: topDirs,
  description,
};

process.stdout.write(JSON.stringify(output, null, 2) + '\n');
