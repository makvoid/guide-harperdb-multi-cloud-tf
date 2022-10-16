'use strict';

const incrementCacheHits = ({ hdbCore, id, hits }) => {
  try {
    const hitRequest = {
      body: {
        operation: 'update',
        schema: 'api_gateway',
        table: 'request_cache',
        hdb_user: { role:{ permission:{ super_user:true } }, username: 'hdbadmin' },
        records: [{ id, hits: hits + 1 }]
      }
    };

    return hdbCore.requestWithoutAuthentication(hitRequest);
  } catch (e) {
    return false;
  }
}

module.exports = incrementCacheHits;
