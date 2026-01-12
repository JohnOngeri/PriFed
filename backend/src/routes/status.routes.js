/**
 * System Status Routes
 * Training status and system information
 */

import express from 'express';
import { authenticate, optionalAuth } from '../middleware/auth.middleware.js';
import * as statusController from '../controllers/status.controller.js';

const router = express.Router();

/**
 * @route   GET /api/status
 * @desc    Get comprehensive system status
 * @access  Public (optional auth for enhanced data)
 */
router.get('/', 
  optionalAuth,
  statusController.getSystemStatus
);

export default router;
