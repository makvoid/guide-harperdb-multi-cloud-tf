'use strict';

const handleRequest = require('../helpers/handleRequest');

module.exports = async (server, { hdbCore, logger }) => {
  server.route({
    url: '/url',
    method: ['DELETE', 'GET', 'HEAD', 'PATCH', 'POST', 'PUT', 'OPTIONS'],
    handler: async (request, reply) => handleRequest({ hdbCore, request, reply, logger }),
  });
};
