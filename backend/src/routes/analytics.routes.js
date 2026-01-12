/**
 * Analytics Routes
 * Fairness analysis and advanced analytics
 */

import express from 'express';
import { authenticate, optionalAuth } from '../middleware/auth.middleware.js';
import * as analyticsController from '../controllers/analytics.controller.js';

const router = express.Router();

/**
 * @route   GET /api/analytics/fairness
 * @desc    Get fairness analysis across banks
 * @access  Public (optional auth)
 */
router.get('/fairness',
  optionalAuth,
  analyticsController.getFairnessAnalysis
);

export default router;
