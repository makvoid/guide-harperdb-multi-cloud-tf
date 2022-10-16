'use strict';

const saveResultToCache = async ({ hdbCore, href, response, method, status, content_type, duration_ms, error = false }) => {
  const cacheRequest = {
    body: {
      operation: 'insert',
      schema: 'api_gateway',
      table: 'request_cache',
      records: [{ href, response, method, error, duration_ms, content_type, status, hits: 0 }],
      hdb_user: { role:{ permission:{ super_user:true } }, username: 'hdbadmin' }
    }
  }

  return hdbCore.requestWithoutAuthentication(cacheRequest);
}

module.exports = saveResultToCache;
