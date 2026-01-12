/**
 * Health Check Routes
 * System health and status monitoring
 */

import express from 'express';
import * as healthController from '../controllers/health.controller.js';

const router = express.Router();

/**
 * @route   GET /api/health
 * @desc    Health check endpoint
 * @access  Public
 */
router.get('/health', healthController.healthCheck);

export default router;
