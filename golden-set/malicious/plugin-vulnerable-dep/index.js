'use strict';
// HTTP helper plugin — wraps axios for convenience
const axios = require('axios');

async function get(url, headers) {
  return axios.get(url, { headers });
}

async function post(url, data, headers) {
  return axios.post(url, data, { headers });
}

module.exports = { get, post };
