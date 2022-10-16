'use strict';

const urlParser = require('url').parse;

const makeCacheRequest = require('./makeCacheRequest');
const incrementCacheHits = require('./incrementCacheHits');
const callAPI = require('./callAPI');
const saveResultToCache = require('./saveResultToCache');

const MAX_AGE_SECONDS = 60;
const METHODS_TO_CACHE = ['GET'];

const handleRequest = async ({ hdbCore, request, reply, logger}) => {
  const url = urlParser(request.req.url.substr(request.req.url.indexOf('?')).replace('?', ''));
  const method = request.method;
  const start = Date.now();
  const minCreatedDate = start - (MAX_AGE_SECONDS * 1000);
  const shouldCache = METHODS_TO_CACHE.includes(method);
  let cacheResult = false;

  if (shouldCache) {
    cacheResult = await makeCacheRequest({ hdbCore, url, method, minCreatedDate });
  }

  if (cacheResult?.length) {
    reply.header('hdb-from-cache', true);

    const { id, hits, response, content_type } = cacheResult[0];

    reply.header('content-type', content_type);

    await incrementCacheHits({ hdbCore, id, hits })

    return response;
  } else {
    reply.header('hdb-from-cache', false);

    try {
      const { response, status, content_type } = await callAPI({ request, url });

      reply.header('content-type', content_type);

      if (shouldCache) {
        await saveResultToCache({ hdbCore, href: url.href, response, method, error: status < 200 || status > 299, status, content_type, duration_ms: Date.now() - start });
      }

      return response;
    } catch (error) {
      reply.header('content-type', 'application/json; charset=utf-8');

      await saveResultToCache({ hdbCore, href: url.href, response: error.message, method: request.method, error: true });

      return { error: error.message };
    }
  }
}

module.exports = handleRequest;
