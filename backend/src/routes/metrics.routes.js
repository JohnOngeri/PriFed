/**
 * Metrics Routes
 * Training metrics, privacy metrics, and rounds history
 */

import express from 'express';
import { authenticate, optionalAuth } from '../middleware/auth.middleware.js';
import * as metricsController from '../controllers/metrics.controller.js';

const router = express.Router();

/**
 * @route   GET /api/metrics/global
 * @desc    Get global model performance metrics
 * @access  Public (optional auth)
 */
router.get('/global',
  optionalAuth,
  metricsController.getGlobalMetrics
);

/**
 * @route   GET /api/metrics/banks
 * @desc    Get performance metrics for all banks
 * @access  Public (optional auth)
 */
router.get('/banks',
  optionalAuth,
  metricsController.getBankMetrics
);

/**
 * @route   GET /api/metrics/banks/:bankId
 * @desc    Get metrics for a specific bank
 * @access  Public (optional auth)
 */
router.get('/banks/:bankId',
  optionalAuth,
  metricsController.getBankMetricsById
);

// Note: /api/privacy and /api/rounds are handled by separate route files
// to ensure correct mounting at root level

export default router;
