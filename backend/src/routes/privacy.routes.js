/**
 * Privacy Routes
 * Privacy metrics endpoint
 */

import express from 'express';
import { optionalAuth } from '../middleware/auth.middleware.js';
import * as metricsController from '../controllers/metrics.controller.js';

const router = express.Router();

/**
 * @route   GET /api/privacy
 * @desc    Get privacy metrics and budget information
 * @access  Public (optional auth)
 */
router.get('/',
  optionalAuth,
  metricsController.getPrivacyMetrics
);

export default router;
