/**
 * Bank Management Controller
 * Bank CRUD operations and federation management
 * CRITICAL: All responses must match Flutter expectations
 */

import prisma from '../utils/prisma.js';
import { logger } from '../utils/logger.js';

/**
 * GET /api/banks
 * Flutter expects: List of BankData objects
 * Response should match: { banks: [{ id, name, subtitle, color, icon, metrics, samples, fraud_rate, time_range }] }
 */
export const getAllBanks = async (req, res) => {
  try {
    // Get all active banks
    const banks = await prisma.bank.findMany({
      where: { isActive: true }
    });

    // Transform to Flutter BankData.fromJson() format
    const banksData = await Promise.all(banks.map(async (bank) => {
      // Get latest bank metrics
      const latestBankMetrics = await prisma.bankMetrics.findFirst({
        where: { bankId: bank.id },
        orderBy: { timestamp: 'desc' },
        include: {
          metrics: true
        }
      });

      // Get latest training round for this bank (ordered by creation date, not nested orderBy)
      const latestTrainingRound = await prisma.bankTrainingRound.findFirst({
        where: { bankId: bank.id },
        orderBy: { createdAt: 'desc' },
        include: {
          metrics: true,
          round: true
        }
      });

      // Extract metrics - prefer from training round (most recent) if available, else from bankMetrics
      const latestMetrics = latestTrainingRound?.metrics || latestBankMetrics?.metrics || null;
      const samples = latestTrainingRound?.samples || 0;
      const fraudRate = latestTrainingRound?.fraudRate || 0.0;

      // Calculate time range (mock for now - would be from actual data)
      const timeRange = _calculateTimeRange(bank.joinedAt);

      // Build metrics (default if no metrics exist)
      const metrics = latestMetrics ? {
        auc: latestMetrics.auc,
        accuracy: latestMetrics.accuracy,
        precision: latestMetrics.precision,
        recall: latestMetrics.recall,
        f1: latestMetrics.f1,
        bank_id: bank.bankId,
        num_samples: samples,
        fraud_rate: fraudRate,
        loss: latestMetrics.loss || null,
        timestamp: latestMetrics.timestamp.toISOString()
      } : {
        auc: 0.85,
        accuracy: 0.82,
        precision: 0.80,
        recall: 0.84,
        f1: 0.82,
        bank_id: bank.bankId,
        num_samples: samples,
        fraud_rate: fraudRate
      };

      return {
        id: bank.bankId, // ✅ Use human-readable bankId as id
        name: bank.name,
        subtitle: bank.subtitle || 'Federation Member',
        color: bank.color || 'blue',
        icon: bank.icon || 'building_modern',
        metrics: metrics,
        samples: samples,
        fraud_rate: fraudRate,
        time_range: timeRange
      };
    }));

    res.json({ banks: banksData });
  } catch (error) {
    logger.error('Get all banks error:', error);
    res.status(500).json({
      error: 'Internal Server Error',
      message: 'Failed to retrieve banks',
      timestamp: new Date().toISOString()
    });
  }
};

/**
 * GET /api/banks/:bankId
 * Get bank by ID
 */
export const getBankById = async (req, res) => {
  try {
    const { bankId } = req.params;

    const bank = await prisma.bank.findUnique({
      where: { bankId }
    });

    if (!bank) {
      return res.status(404).json({
        error: 'Not Found',
        message: `Bank ${bankId} not found`,
        timestamp: new Date().toISOString()
      });
    }

    // Get latest bank metrics
    const latestBankMetrics = await prisma.bankMetrics.findFirst({
      where: { bankId: bank.id },
      orderBy: { timestamp: 'desc' },
      include: {
        metrics: true
      }
    });

    // Get latest training round for this bank (ordered by creation date)
    const latestTrainingRound = await prisma.bankTrainingRound.findFirst({
      where: { bankId: bank.id },
      orderBy: { createdAt: 'desc' },
      include: {
        metrics: true,
        round: true
      }
    });

    // Extract metrics - prefer from training round (most recent) if available, else from bankMetrics
    const latestMetrics = latestTrainingRound?.metrics || latestBankMetrics?.metrics || null;
    const samples = latestTrainingRound?.samples || 0;
    const fraudRate = latestTrainingRound?.fraudRate || 0.0;
    const timeRange = _calculateTimeRange(bank.joinedAt);

    const metrics = latestMetrics ? {
      auc: latestMetrics.auc,
      accuracy: latestMetrics.accuracy,
      precision: latestMetrics.precision,
      recall: latestMetrics.recall,
      f1: latestMetrics.f1,
      bank_id: bank.bankId,
      num_samples: samples,
      fraud_rate: fraudRate,
      loss: latestMetrics.loss || null,
      timestamp: latestMetrics.timestamp.toISOString()
    } : {
      auc: 0.85,
      accuracy: 0.82,
      precision: 0.80,
      recall: 0.84,
      f1: 0.82,
      bank_id: bank.bankId,
      num_samples: samples,
      fraud_rate: fraudRate
    };

    const response = {
      id: bank.bankId,
      name: bank.name,
      subtitle: bank.subtitle || 'Federation Member',
      color: bank.color || 'blue',
      icon: bank.icon || 'building_modern',
      metrics: metrics,
      samples: samples,
      fraud_rate: fraudRate,
      time_range: timeRange
    };

    res.json(response);
  } catch (error) {
    logger.error('Get bank by ID error:', error);
    res.status(500).json({
      error: 'Internal Server Error',
      message: `Failed to retrieve bank ${req.params.bankId}`,
      timestamp: new Date().toISOString()
    });
  }
};

/**
 * POST /api/banks
 * Create new bank (Admin only - already checked in route)
 */
export const createBank = async (req, res) => {
  try {
    const { bankId, name, subtitle, color, icon } = req.body;

    // Check if bank already exists
    const existingBank = await prisma.bank.findUnique({
      where: { bankId }
    });

    if (existingBank) {
      return res.status(409).json({
        error: 'Conflict',
        message: `Bank with ID ${bankId} already exists`,
        timestamp: new Date().toISOString()
      });
    }

    // Create bank
    const bank = await prisma.bank.create({
      data: {
        bankId: bankId,
        name: name,
        subtitle: subtitle || null,
        color: color || 'blue',
        icon: icon || 'building_modern',
        isActive: true
      }
    });

    // Create default metrics entry for the new bank
    try {
      const defaultMetrics = await prisma.classificationMetrics.create({
        data: {
          auc: 0.85,
          accuracy: 0.82,
          precision: 0.80,
          recall: 0.84,
          f1: 0.82,
          loss: 0.0
        }
      });

      await prisma.bankMetrics.create({
        data: {
          bankId: bank.id,
          metricsId: defaultMetrics.id,
          roundNumber: null,
          samples: 0,
          fraudRate: 0.0
        }
      });
    } catch (metricsError) {
      // Log but don't fail bank creation if metrics creation fails
      logger.warn('Failed to create default metrics for new bank:', metricsError);
    }

    // Create notification for all admin users
    await _createNotification(
      null, // System notification (no specific user)
      'BANK_APPLICATION', // NotificationType enum value
      'New Bank Added',
      `${name} (${bankId}) has been added to the federation by ${req.user.email}`,
      { bankId: bank.bankId, bankName: name }
    );

    logger.info('Bank created', { bankId, createdBy: req.user.email });

    res.status(201).json({
      message: 'Bank created successfully',
      bank: {
        id: bank.bankId,
        name: bank.name,
        subtitle: bank.subtitle,
        color: bank.color,
        icon: bank.icon,
        isActive: bank.isActive,
        joinedAt: bank.joinedAt.toISOString()
      },
      timestamp: new Date().toISOString()
    });
  } catch (error) {
    logger.error('Create bank error:', error);
    res.status(500).json({
      error: 'Internal Server Error',
      message: 'Failed to create bank',
      timestamp: new Date().toISOString()
    });
  }
};

/**
 * PUT /api/banks/:bankId
 * Update bank information (Admin only)
 */
export const updateBank = async (req, res) => {
  try {
    const { bankId } = req.params;
    const { name, subtitle, color, icon, isActive } = req.body;

    // Find bank
    const bank = await prisma.bank.findUnique({
      where: { bankId }
    });

    if (!bank) {
      return res.status(404).json({
        error: 'Not Found',
        message: `Bank ${bankId} not found`,
        timestamp: new Date().toISOString()
      });
    }

    // Update bank
    const updatedBank = await prisma.bank.update({
      where: { bankId },
      data: {
        ...(name && { name }),
        ...(subtitle !== undefined && { subtitle }),
        ...(color && { color }),
        ...(icon && { icon }),
        ...(isActive !== undefined && { isActive })
      }
    });

    logger.info('Bank updated', { bankId, updatedBy: req.user.email });

    res.json({
      message: 'Bank updated successfully',
      bank: {
        id: updatedBank.bankId,
        name: updatedBank.name,
        subtitle: updatedBank.subtitle,
        color: updatedBank.color,
        icon: updatedBank.icon,
        isActive: updatedBank.isActive
      },
      timestamp: new Date().toISOString()
    });
  } catch (error) {
    logger.error('Update bank error:', error);
    res.status(500).json({
      error: 'Internal Server Error',
      message: 'Failed to update bank',
      timestamp: new Date().toISOString()
    });
  }
};

/**
 * DELETE /api/banks/:bankId
 * Remove bank from federation (Admin only)
 */
export const deleteBank = async (req, res) => {
  try {
    const { bankId } = req.params;

    // Find bank
    const bank = await prisma.bank.findUnique({
      where: { bankId },
      include: {
        users: {
          select: { id: true }
        }
      }
    });

    if (!bank) {
      return res.status(404).json({
        error: 'Not Found',
        message: `Bank ${bankId} not found`,
        timestamp: new Date().toISOString()
      });
    }

    // Soft delete (set isActive = false) instead of hard delete
    // This preserves historical data
    await prisma.bank.update({
      where: { bankId },
      data: { isActive: false }
    });

    // Create notification
    await _createNotification(
      null,
      'BANK_APPLICATION', // NotificationType enum value
      'Bank Removed',
      `${bank.name} (${bankId}) has been removed from the federation by ${req.user.email}`,
      { bankId: bank.bankId, bankName: bank.name }
    );

    logger.info('Bank removed', { bankId, removedBy: req.user.email });

    res.json({
      message: 'Bank removed from federation successfully',
      timestamp: new Date().toISOString()
    });
  } catch (error) {
    logger.error('Delete bank error:', error);
    res.status(500).json({
      error: 'Internal Server Error',
      message: 'Failed to remove bank',
      timestamp: new Date().toISOString()
    });
  }
};

/**
 * POST /api/banks/applications
 * Submit bank application to join federation
 */
export const createBankApplication = async (req, res) => {
  try {
    const { bankId, bankName, licenseNumber, contactEmail, contactPhone, address } = req.body;

    // Check if bank already exists
    const existingBank = await prisma.bank.findUnique({
      where: { bankId }
    });

    if (existingBank) {
      return res.status(409).json({
        error: 'Conflict',
        message: `Bank with ID ${bankId} already exists`,
        timestamp: new Date().toISOString()
      });
    }

    // Check if application already exists
    const existingApplication = await prisma.bankApplication.findUnique({
      where: { bankId }
    });

    if (existingApplication) {
      return res.status(409).json({
        error: 'Conflict',
        message: `Application for bank ${bankId} already exists`,
        timestamp: new Date().toISOString()
      });
    }

    // Create application
    const application = await prisma.bankApplication.create({
      data: {
        bankId: bankId,
        bankName: bankName,
        licenseNumber: licenseNumber,
        contactEmail: contactEmail,
        contactPhone: contactPhone,
        address: address,
        status: 'PENDING'
      }
    });

    // Create notifications for all admin and bank admin users
    const admins = await prisma.user.findMany({
      where: {
        role: { in: ['ADMIN', 'BANK_ADMIN'] },
        isActive: true
      }
    });

    for (const admin of admins) {
      await _createNotification(
        admin.id,
        'BANK_APPLICATION', // NotificationType enum value
        'New Bank Application',
        `${bankName} (${bankId}) has applied to join the federation`,
        { applicationId: application.id, bankId: bankId, bankName: bankName }
      );
    }

    logger.info('Bank application created', { applicationId: application.id, bankId });

    res.status(201).json({
      message: 'Bank application submitted successfully',
      application: {
        id: application.id,
        bankId: application.bankId,
        bankName: application.bankName,
        status: application.status.toLowerCase(),
        submittedAt: application.submittedAt.toISOString()
      },
      timestamp: new Date().toISOString()
    });
  } catch (error) {
    logger.error('Create bank application error:', error);
    res.status(500).json({
      error: 'Internal Server Error',
      message: 'Failed to submit bank application',
      timestamp: new Date().toISOString()
    });
  }
};

/**
 * GET /api/banks/applications
 * Get all bank applications (Admin/Bank Admin only)
 */
export const getBankApplications = async (req, res) => {
  try {
    const applications = await prisma.bankApplication.findMany({
      orderBy: { submittedAt: 'desc' },
      include: {
        votes: {
          include: {
            bank: true
          }
        }
      }
    });

    // Transform to Flutter BankApplication format
    const applicationsData = applications.map(app => ({
      id: app.id,
      bankName: app.bankName,
      bankId: app.bankId,
      licenseNumber: app.licenseNumber,
      contactEmail: app.contactEmail,
      contactPhone: app.contactPhone,
      address: app.address,
      submittedAt: app.submittedAt.toISOString(),
      status: app.status.toLowerCase(), // 'pending', 'approved', 'rejected'
      votes: app.votes.map(vote => ({
        bankId: vote.bank.bankId,
        vote: vote.vote.toLowerCase(), // 'approve' or 'reject'
        createdAt: vote.createdAt.toISOString()
      }))
    }));

    res.json({
      applications: applicationsData,
      timestamp: new Date().toISOString()
    });
  } catch (error) {
    logger.error('Get bank applications error:', error);
    res.status(500).json({
      error: 'Internal Server Error',
      message: 'Failed to retrieve bank applications',
      timestamp: new Date().toISOString()
    });
  }
};

/**
 * GET /api/banks/applications/:applicationId
 * Get bank application by ID
 */
export const getBankApplicationById = async (req, res) => {
  try {
    const { applicationId } = req.params;

    const application = await prisma.bankApplication.findUnique({
      where: { id: applicationId },
      include: {
        votes: {
          include: {
            bank: true
          }
        }
      }
    });

    if (!application) {
      return res.status(404).json({
        error: 'Not Found',
        message: `Application ${applicationId} not found`,
        timestamp: new Date().toISOString()
      });
    }

    const response = {
      id: application.id,
      bankName: application.bankName,
      bankId: application.bankId,
      licenseNumber: application.licenseNumber,
      contactEmail: application.contactEmail,
      contactPhone: application.contactPhone,
      address: application.address,
      submittedAt: application.submittedAt.toISOString(),
      status: application.status.toLowerCase(),
      reviewedAt: application.reviewedAt?.toISOString() || null,
      approvedAt: application.approvedAt?.toISOString() || null,
      rejectedAt: application.rejectedAt?.toISOString() || null,
      notes: application.notes || null,
      votes: application.votes.map(vote => ({
        bankId: vote.bank.bankId,
        vote: vote.vote.toLowerCase(),
        createdAt: vote.createdAt.toISOString()
      }))
    };

    res.json(response);
  } catch (error) {
    logger.error('Get bank application by ID error:', error);
    res.status(500).json({
      error: 'Internal Server Error',
      message: `Failed to retrieve application ${req.params.applicationId}`,
      timestamp: new Date().toISOString()
    });
  }
};

/**
 * POST /api/banks/applications/:applicationId/vote
 * Vote on bank application (Bank Admin only)
 */
export const voteOnApplication = async (req, res) => {
  try {
    const { applicationId } = req.params;
    const { vote } = req.body; // 'APPROVE' or 'REJECT'

    // Get current user's bank
    if (!req.user.bankId) {
      return res.status(403).json({
        error: 'Forbidden',
        message: 'You must be associated with a bank to vote',
        timestamp: new Date().toISOString()
      });
    }

    const bank = await prisma.bank.findUnique({
      where: { id: req.user.bankId }
    });

    if (!bank) {
      return res.status(404).json({
        error: 'Not Found',
        message: 'Your associated bank not found',
        timestamp: new Date().toISOString()
      });
    }

    // Get application
    const application = await prisma.bankApplication.findUnique({
      where: { id: applicationId },
      include: {
        votes: {
          include: {
            bank: true
          }
        }
      }
    });

    if (!application) {
      return res.status(404).json({
        error: 'Not Found',
        message: `Application ${applicationId} not found`,
        timestamp: new Date().toISOString()
      });
    }

    if (application.status !== 'PENDING') {
      return res.status(400).json({
        error: 'Bad Request',
        message: `Application is already ${application.status.toLowerCase()}`,
        timestamp: new Date().toISOString()
      });
    }

    // Check if bank already voted
    const existingVote = application.votes.find(v => v.bank.id === bank.id);
    
    let voteRecord;
    if (existingVote) {
      // Update existing vote
      voteRecord = await prisma.bankApplicationVote.update({
        where: { id: existingVote.id },
        data: { vote: vote.toUpperCase() }
      });
    } else {
      // Create new vote
      voteRecord = await prisma.bankApplicationVote.create({
        data: {
          applicationId: application.id,
          bankId: bank.id,
          vote: vote.toUpperCase()
        }
      });
    }

    // Check if we have 2/3 majority (consensus)
    const allBanks = await prisma.bank.count({ where: { isActive: true } });
    const allVotes = await prisma.bankApplicationVote.findMany({
      where: { applicationId: application.id },
      include: { bank: true }
    });

    const approveVotes = allVotes.filter(v => v.vote === 'APPROVE').length;
    const rejectVotes = allVotes.filter(v => v.vote === 'REJECT').length;
    const requiredVotes = Math.ceil(allBanks * (2 / 3));

    let updatedApplication = application;

    if (approveVotes >= requiredVotes) {
      // Approve application - create bank
      await prisma.bank.create({
        data: {
          bankId: application.bankId,
          name: application.bankName,
          subtitle: 'New Member',
          color: 'blue',
          icon: 'building_modern',
          isActive: true
        }
      });

      updatedApplication = await prisma.bankApplication.update({
        where: { id: applicationId },
        data: {
          status: 'APPROVED',
          approvedAt: new Date(),
          reviewedAt: new Date()
        }
      });

      // Create notification
      await _createNotification(
        null,
        'BANK_APPLICATION', // NotificationType enum value
        'Bank Application Approved',
        `${application.bankName} has been approved and joined the federation!`,
        { applicationId: application.id, bankId: application.bankId, bankName: application.bankName }
      );

      logger.info('Bank application approved', { applicationId, bankId: application.bankId });

    } else if (rejectVotes >= requiredVotes) {
      // Reject application
      updatedApplication = await prisma.bankApplication.update({
        where: { id: applicationId },
        data: {
          status: 'REJECTED',
          rejectedAt: new Date(),
          reviewedAt: new Date()
        }
      });

      // Create notification
      await _createNotification(
        null,
        'BANK_APPLICATION', // NotificationType enum value
        'Bank Application Rejected',
        `Application from ${application.bankName} has been rejected by consensus`,
        { applicationId: application.id, bankId: application.bankId, bankName: application.bankName }
      );

      logger.info('Bank application rejected', { applicationId, bankId: application.bankId });
    }

    res.json({
      message: 'Vote recorded successfully',
      vote: vote.toLowerCase(),
      approvalVotes: approveVotes,
      rejectionVotes: rejectVotes,
      requiredVotes: requiredVotes,
      totalBanks: allBanks,
      status: updatedApplication.status.toLowerCase(),
      ...(updatedApplication.status !== 'PENDING' && {
        message: `Application has been ${updatedApplication.status.toLowerCase()} by consensus`
      }),
      timestamp: new Date().toISOString()
    });
  } catch (error) {
    logger.error('Vote on application error:', error);
    res.status(500).json({
      error: 'Internal Server Error',
      message: 'Failed to record vote',
      timestamp: new Date().toISOString()
    });
  }
};

/**
 * Helper function to calculate time range
 */
function _calculateTimeRange(joinedAt) {
  const now = new Date();
  const joined = new Date(joinedAt);
  const monthsDiff = (now.getFullYear() - joined.getFullYear()) * 12 + (now.getMonth() - joined.getMonth());
  
  if (monthsDiff < 1) {
    return 'New';
  } else if (monthsDiff <= 3) {
    const months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
    return `${months[joined.getMonth()]}-${months[now.getMonth()]} ${now.getFullYear()}`;
  } else {
    return `${joined.toLocaleDateString('en-US', { month: 'short', year: 'numeric' })} - ${now.toLocaleDateString('en-US', { month: 'short', year: 'numeric' })}`;
  }
}

/**
 * Helper function to create notifications
 */
async function _createNotification(userId, type, title, message, metadata = null) {
  try {
    // Prisma enum values must match schema exactly (SYSTEM, BANK_APPLICATION, etc.)
    await prisma.notification.create({
      data: {
        userId: userId,
        type: type, // String value matching NotificationType enum
        title: title,
        message: message,
        isRead: false,
        metadata: metadata
      }
    });
  } catch (error) {
    logger.error('Failed to create notification:', error);
  }
}
