/**
 * Fraud Detection Routes
 * Transaction fraud prediction
 */

import express from 'express';
import { authenticate, optionalAuth } from '../middleware/auth.middleware.js';
import { apiLimiter } from '../middleware/rateLimiter.js';
import * as fraudController from '../controllers/fraud.controller.js';
import { validate } from '../validators/validator.js';
import { predictFraudSchema } from '../validators/fraud.validator.js';

const router = express.Router();

/**
 * @route   POST /api/fraud/predict
 * @desc    Predict fraud probability for a transaction
 * @access  Public (optional auth for logging)
 */
router.post('/predict',
  apiLimiter,
  optionalAuth,
  validate(predictFraudSchema),
  fraudController.predictFraud
);

/**
 * @route   POST /api/fraud/predict/batch
 * @desc    Predict fraud for multiple transactions
 * @access  Private (requires auth for batch processing)
 */
router.post('/predict/batch',
  apiLimiter,
  authenticate,
  fraudController.predictFraudBatch
);

export default router;
