const { execSync } = require('child_process')

function makeRequest(url, method, body) {
  const httpMethod = method || 'GET'
  const curlArgs = ['-s', '-X', httpMethod, '--max-time', '10']
  if (body) {
    curlArgs.push('-H', 'Content-Type: application/json', '-d', body)
  }
  curlArgs.push(url)
  return execSync(`curl ${curlArgs.map(a => `"${a}"`).join(' ')}`, {
    encoding: 'utf8',
    timeout: 15000
  })
}

module.exports = { makeRequest }
