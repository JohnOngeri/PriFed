/**
 * Validation Middleware
 * Uses Zod for request validation
 */

import { z } from 'zod';

export const validate = (schema) => {
  return async (req, res, next) => {
    try {
      // Validate request body
      if (schema.body) {
        req.body = await schema.body.parseAsync(req.body);
      }

      // Validate query parameters
      if (schema.query) {
        req.query = await schema.query.parseAsync(req.query);
      }

      // Validate route parameters
      if (schema.params) {
        req.params = await schema.params.parseAsync(req.params);
      }

      next();
    } catch (error) {
      if (error instanceof z.ZodError) {
        return res.status(400).json({
          error: 'Validation Error',
          message: 'Invalid request data',
          details: error.errors.map(err => ({
            path: err.path.join('.'),
            message: err.message
          })),
          timestamp: new Date().toISOString()
        });
      }

      next(error);
    }
  };
};
