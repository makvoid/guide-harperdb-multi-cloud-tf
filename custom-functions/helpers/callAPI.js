'use strict';

const https = require('https');
const http = require('http');

const httpAgent = new http.Agent();
const httpsAgent = new https.Agent({ rejectUnauthorized: false });

const callAPI = ({ request, url }) => {
  return new Promise((resolve, reject) => {
    const callback = (response) => {
      let str = '';

      response.on('data', (chunk) => { str += chunk; });
      response.on('end', () => {
        try {
          resolve({ response: JSON.parse(str), status: response.statusCode, content_type: response.headers['content-type'] });
        } catch(e) {
          resolve({ response: str, status: response.statusCode, content_type: response.headers['content-type'] });
        }
      });
    };

    const body = request.body ? JSON.stringify(request.body) : false;
    const options = {
      host: url.host,
      port: url.port,
      protocol: url.protocol,
      path: url.path,
      method: request.method,
      agent: url.protocol === 'http:' ? httpAgent : httpsAgent,
      headers: request.headers,
    };

    const req = (options.protocol === 'https:' ? https : http).request(options, callback);
    req.on('error', (e) => { reject(e); });
    if (body) {
      req.write(body);
    }
    req.end();
  });
}

module.exports = callAPI;
