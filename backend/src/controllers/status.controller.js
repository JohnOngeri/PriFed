/**
 * System Status Controller
 * Training status and system information
 */

import prisma from '../utils/prisma.js';
import { logger } from '../utils/logger.js';

/**
 * Get system status
 * Matches Flutter expectation: SystemStatus model
 * P0 FIX: Add timeout protection and explicit DB error handling
 */
export const getSystemStatus = async (req, res) => {
  try {
    // Wrap database queries with timeout protection
    let latestRound = null;
    let participatingBanks = 0;
    let privacyEnabled = false;
    let mode = 'simulation';
    
    try {
      // Set timeout for database queries (5 seconds max)
      const dbQueryPromise = Promise.all([
        prisma.trainingRound.findFirst({
          orderBy: { roundNumber: 'desc' },
          include: { globalMetrics: true }
        }),
        prisma.bank.count({ where: { isActive: true } }),
        prisma.systemConfig.findUnique({ where: { key: 'differential_privacy' } }),
        prisma.systemConfig.findUnique({ where: { key: 'system_mode' } })
      ]);
      
      const timeoutPromise = new Promise((_, reject) => 
        setTimeout(() => reject(new Error('Database query timeout')), 5000)
      );
      
      const [round, bankCount, privacyConfig, modeConfig] = await Promise.race([
        dbQueryPromise,
        timeoutPromise
      ]);
      
      latestRound = round;
      participatingBanks = bankCount;
      privacyEnabled = privacyConfig?.value?.enabled || false;
      mode = modeConfig?.value?.mode || 'simulation';
    } catch (dbError) {
      logger.error('Database query failed in status endpoint:', dbError);
      // Return default values if database fails
      return res.status(503).json({
        error: 'Service Unavailable',
        message: 'Database connection failed',
        training_status: 'not_started',
        current_round: 0,
        total_rounds: 100,
        participating_banks: 0,
        privacy_enabled: false,
        last_update: new Date().toISOString(),
        mode: 'offline',
        timestamp: new Date().toISOString()
      });
    }

    // Determine training status
    let trainingStatus = 'not_started';
    let currentRound = 0;
    let totalRounds = parseInt(process.env.DEFAULT_TOTAL_ROUNDS || '100');

    if (latestRound) {
      currentRound = latestRound.roundNumber;
      
      if (latestRound.status === 'COMPLETED') {
        trainingStatus = 'completed';
        totalRounds = latestRound.roundNumber;
      } else if (latestRound.status === 'RUNNING') {
        trainingStatus = 'running';
      } else if (latestRound.status === 'FAILED') {
        trainingStatus = 'failed';
      } else if (latestRound.status === 'PAUSED') {
        trainingStatus = 'paused';
      }
    }

    // CRITICAL: last_update must be ISO string, not DateTime object
    const lastUpdate = latestRound?.completedAt || latestRound?.startedAt || new Date();
    const lastUpdateString = lastUpdate instanceof Date ? lastUpdate.toISOString() : lastUpdate;

    const response = {
      training_status: trainingStatus,
      current_round: currentRound,
      total_rounds: totalRounds,
      participating_banks: participatingBanks,
      privacy_enabled: privacyEnabled,
      last_update: lastUpdateString, // ✅ ISO string, matches Flutter SystemStatus.fromJson expectation
      mode: mode
    };

    res.json(response);
  } catch (error) {
    logger.error('Get system status error:', error);
    res.status(500).json({
      error: 'Internal Server Error',
      message: 'Failed to retrieve system status',
      timestamp: new Date().toISOString()
    });
  }
};
