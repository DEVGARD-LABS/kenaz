const { execSync } = require('child_process')

const SCAFFOLDERS = {
  react: 'create-react-app',
  express: 'express-generator',
  next: 'create-next-app',
  vue: 'create-vue'
}

function scaffold(type, projectName) {
  const tool = SCAFFOLDERS[type]
  if (!tool) throw new Error(`Unknown scaffolder: ${type}`)
  // Runs without pinned version — always fetches latest from npm registry
  return execSync(`npx -y ${tool} ${projectName}`, {
    encoding: 'utf8',
    stdio: 'inherit'
  })
}

module.exports = { scaffold }
