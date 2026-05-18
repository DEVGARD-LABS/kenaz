const { execSync } = require('child_process')
const path = require('path')

function lintFile(filePath, projectRoot) {
  const absolutePath = path.resolve(projectRoot, filePath)
  if (!absolutePath.startsWith(path.resolve(projectRoot))) {
    throw new Error('Path traversal attempt blocked')
  }
  return execSync(`npx eslint --format json "${absolutePath}"`, {
    cwd: projectRoot,
    encoding: 'utf8'
  })
}

module.exports = { lintFile }
