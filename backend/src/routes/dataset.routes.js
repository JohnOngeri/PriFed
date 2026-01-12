/**
 * Dataset Routes
 * Dataset information and statistics
 */

import express from 'express';
import { optionalAuth } from '../middleware/auth.middleware.js';
import * as datasetController from '../controllers/dataset.controller.js';

const router = express.Router();

/**
 * @route   GET /api/dataset/info
 * @desc    Get dataset information and statistics
 * @access  Public
 */
router.get('/info',
  optionalAuth,
  datasetController.getDatasetInfo
);

export default router;
