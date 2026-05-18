const { execSync } = require('child_process')
const path = require('path')

const ALLOWED_COMMANDS = [
  'git status',
  'git log --oneline',
  'git diff',
  'git branch'
]

function runGitCommand(cmd, projectDir) {
  if (!ALLOWED_COMMANDS.some(allowed => cmd.startsWith(allowed))) {
    throw new Error(`Command not in allowlist: ${cmd}`)
  }
  const resolved = path.resolve(projectDir)
  return execSync(cmd, { cwd: resolved, encoding: 'utf8' })
}

module.exports = { runGitCommand }
