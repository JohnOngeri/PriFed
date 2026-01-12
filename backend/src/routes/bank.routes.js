/**
 * Bank Management Routes
 * Bank CRUD operations and federation management
 */

import express from 'express';
import { authenticate } from '../middleware/auth.middleware.js';
import { requireAdmin, requireBankAdmin } from '../middleware/auth.middleware.js';
import * as bankController from '../controllers/bank.controller.js';
import { validate } from '../validators/validator.js';
import { 
  createBankSchema, 
  updateBankSchema, 
  createBankApplicationSchema,
  voteOnApplicationSchema 
} from '../validators/bank.validator.js';

const router = express.Router();

/**
 * @route   GET /api/banks
 * @desc    Get all participating banks
 * @access  Public
 */
router.get('/',
  bankController.getAllBanks
);

/**
 * @route   GET /api/banks/:bankId
 * @desc    Get bank by ID
 * @access  Public
 */
router.get('/:bankId',
  bankController.getBankById
);

/**
 * @route   POST /api/banks
 * @desc    Add new bank to federation (Admin only)
 * @access  Private (Admin)
 */
router.post('/',
  authenticate,
  requireAdmin,
  validate(createBankSchema),
  bankController.createBank
);

/**
 * @route   PUT /api/banks/:bankId
 * @desc    Update bank information (Admin only)
 * @access  Private (Admin)
 */
router.put('/:bankId',
  authenticate,
  requireAdmin,
  validate(updateBankSchema),
  bankController.updateBank
);

/**
 * @route   DELETE /api/banks/:bankId
 * @desc    Remove bank from federation (Admin only)
 * @access  Private (Admin)
 */
router.delete('/:bankId',
  authenticate,
  requireAdmin,
  bankController.deleteBank
);

/**
 * @route   POST /api/banks/applications
 * @desc    Submit bank application to join federation
 * @access  Public
 */
router.post('/applications',
  validate(createBankApplicationSchema),
  bankController.createBankApplication
);

/**
 * @route   GET /api/banks/applications
 * @desc    Get all bank applications (Admin/Bank Admin)
 * @access  Private (Admin/Bank Admin)
 */
router.get('/applications',
  authenticate,
  requireBankAdmin,
  bankController.getBankApplications
);

/**
 * @route   GET /api/banks/applications/:applicationId
 * @desc    Get bank application by ID
 * @access  Private (Admin/Bank Admin)
 */
router.get('/applications/:applicationId',
  authenticate,
  requireBankAdmin,
  bankController.getBankApplicationById
);

/**
 * @route   POST /api/banks/applications/:applicationId/vote
 * @desc    Vote on bank application (Bank Admin only)
 * @access  Private (Bank Admin)
 */
router.post('/applications/:applicationId/vote',
  authenticate,
  requireBankAdmin,
  validate(voteOnApplicationSchema),
  bankController.voteOnApplication
);

export default router;
