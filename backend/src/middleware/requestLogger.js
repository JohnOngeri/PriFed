/**
 * Request Logging Middleware
 * Logs all incoming requests for monitoring and debugging
 */

import { logger } from '../utils/logger.js';

export const requestLogger = (req, res, next) => {
  const startTime = Date.now();

  // Log request
  logger.info('Incoming request', {
    method: req.method,
    path: req.path,
    ip: req.ip,
    userAgent: req.get('user-agent')
  });

  // Store original end function to intercept response
  const originalEnd = res.end;
  const originalSend = res.send;

  // Override send to set header before response is sent
  res.send = function(body) {
    const duration = Date.now() - startTime;
    if (!res.headersSent) {
      res.setHeader('X-Process-Time', `${duration}ms`);
    }
    return originalSend.call(this, body);
  };

  // Override end to set header before response is sent
  res.end = function(chunk, encoding) {
    const duration = Date.now() - startTime;
    if (!res.headersSent) {
      res.setHeader('X-Process-Time', `${duration}ms`);
    }
    return originalEnd.call(this, chunk, encoding);
  };

  // Capture response finish for logging (after headers are sent)
  res.on('finish', () => {
    const duration = Date.now() - startTime;
    const logLevel = res.statusCode >= 400 ? 'warn' : 'info';

    logger[logLevel]('Request completed', {
      method: req.method,
      path: req.path,
      statusCode: res.statusCode,
      duration: `${duration}ms`,
      ip: req.ip
    });
  });

  next();
};
