'use strict';

module.exports = async (server, { hdbCore, logger }) => {
  server.route({
    url: '/setup',
    method: 'GET',
    handler: async (request) => {
      const results = {};

      request.body = {
        operation: 'create_schema',
        schema: 'api_gateway'
      }

      try {
        results.schema_result = await hdbCore.requestWithoutAuthentication(request);
      } catch (e) {
        results.schema_result = e;
      }

      request.body = {
        operation: 'create_table',
        schema: 'api_gateway',
        table: 'request_cache',
        hash_attribute: 'id'
      }

      try {
        results.cache_table_result = await hdbCore.requestWithoutAuthentication(request);
      } catch (e) {
        results.cache_table_result = e;
      }

      return results;
    }
  });

};
