/**
 * Training Rounds Routes
 * Training rounds history endpoint
 */

import express from 'express';
import { optionalAuth } from '../middleware/auth.middleware.js';
import * as metricsController from '../controllers/metrics.controller.js';

const router = express.Router();

/**
 * @route   GET /api/rounds
 * @desc    Get training rounds history with pagination
 * @access  Public (optional auth)
 */
router.get('/',
  optionalAuth,
  metricsController.getTrainingRounds
);

export default router;
