/**
 * Training Results Routes
 * Endpoints for storing training results from Python training scripts
 */

import express from 'express';
import { authenticate, optionalAuth } from '../middleware/auth.middleware.js';
import * as trainingController from '../controllers/training.controller.js';
import { validate } from '../validators/validator.js';
import { storeTrainingRoundSchema } from '../validators/training.validator.js';

const router = express.Router();

/**
 * @route   POST /api/training/rounds
 * @desc    Store a training round's results (called by Python scripts)
 * @access  Public (but should be restricted in production - use API key)
 */
router.post('/rounds',
  optionalAuth, // Allow unauthenticated for Python scripts (can be changed to require API key)
  validate(storeTrainingRoundSchema),
  trainingController.storeTrainingRound
);

/**
 * @route   POST /api/training/rounds/batch
 * @desc    Store multiple training rounds at once
 * @access  Public (but should be restricted in production)
 */
router.post('/rounds/batch',
  optionalAuth,
  // Batch endpoint accepts array directly, skip strict validation
  trainingController.storeTrainingRoundsBatch
);

/**
 * @route   POST /api/training/sync
 * @desc    Sync complete training results from JSON data (convenience endpoint)
 * @access  Public (but should be restricted in production)
 */
router.post('/sync',
  optionalAuth,
  // Sync endpoint accepts flexible structure, skip strict validation
  trainingController.syncTrainingResults
);

export default router;
