/**
 * Metrics Controller
 * Training metrics, privacy metrics, and rounds history
 * CRITICAL: All responses must match Flutter fromJson() expectations exactly
 */

import prisma from '../utils/prisma.js';
import { logger } from '../utils/logger.js';

/**
 * GET /api/metrics/global
 * Flutter expects: { round, metrics: { auc, accuracy, precision, recall, f1 }, loss, convergence_rate }
 */
export const getGlobalMetrics = async (req, res) => {
  try {
    const roundNum = req.query.round_num ? parseInt(req.query.round_num) : null;

    // Find training round (specific or latest)
    let trainingRound = null;
    
    if (roundNum) {
      trainingRound = await prisma.trainingRound.findUnique({
        where: { roundNumber: roundNum },
        include: {
          globalMetrics: true
        }
      });
      
      if (!trainingRound) {
        return res.status(404).json({
          error: 'Not Found',
          message: `Round ${roundNum} not found`,
          timestamp: new Date().toISOString()
        });
      }
    } else {
      // Get latest round
      trainingRound = await prisma.trainingRound.findFirst({
        orderBy: { roundNumber: 'desc' },
        include: {
          globalMetrics: true
        }
      });
    }

    // If no rounds exist, return default metrics
    if (!trainingRound) {
      return res.json({
        round: 0,
        metrics: {
          auc: 0.0,
          accuracy: 0.0,
          precision: 0.0,
          recall: 0.0,
          f1: 0.0
        },
        loss: 0.0,
        convergence_rate: 0.0
      });
    }

    const globalMetrics = trainingRound.globalMetrics;

    // Calculate convergence rate if multiple rounds available
    let convergenceRate = 0.0;
    if (!roundNum) {
      const previousRound = await prisma.trainingRound.findFirst({
        where: {
          roundNumber: { lt: trainingRound.roundNumber }
        },
        orderBy: { roundNumber: 'desc' },
        include: { globalMetrics: true }
      });

      if (previousRound) {
        convergenceRate = globalMetrics.auc - previousRound.globalMetrics.auc;
      }
    }

    // CRITICAL: Response format must match Flutter BankMetrics.fromJson() expectations
    const response = {
      round: trainingRound.roundNumber,
      metrics: {
        auc: globalMetrics.auc,
        accuracy: globalMetrics.accuracy,
        precision: globalMetrics.precision,
        recall: globalMetrics.recall,
        f1: globalMetrics.f1,
        loss: globalMetrics.loss || 0.0,
        ...(globalMetrics.specificity !== null && { specificity: globalMetrics.specificity })
      },
      loss: globalMetrics.loss || 0.0,
      convergence_rate: convergenceRate
    };

    res.json(response);
  } catch (error) {
    logger.error('Get global metrics error:', error);
    res.status(500).json({
      error: 'Internal Server Error',
      message: 'Failed to retrieve global metrics',
      timestamp: new Date().toISOString()
    });
  }
};

/**
 * GET /api/metrics/banks
 * Flutter expects: { round, bank_metrics: { bank_a: {...}, bank_b: {...} }, timestamp }
 */
export const getBankMetrics = async (req, res) => {
  try {
    const roundNum = req.query.round_num ? parseInt(req.query.round_num) : null;

    // Find training round (specific or latest)
    let trainingRound = null;
    
    if (roundNum) {
      trainingRound = await prisma.trainingRound.findUnique({
        where: { roundNumber: roundNum },
        include: {
          bankRounds: {
            include: {
              bank: true,
              metrics: true
            }
          }
        }
      });
      
      if (!trainingRound) {
        return res.status(404).json({
          error: 'Not Found',
          message: `Round ${roundNum} not found`,
          timestamp: new Date().toISOString()
        });
      }
    } else {
      // Get latest round
      trainingRound = await prisma.trainingRound.findFirst({
        orderBy: { roundNumber: 'desc' },
        include: {
          bankRounds: {
            include: {
              bank: true,
              metrics: true
            }
          }
        }
      });
    }

    // Build bank_metrics map matching Flutter expectation
    const bankMetrics = {};
    
    if (trainingRound && trainingRound.bankRounds) {
      for (const bankRound of trainingRound.bankRounds) {
        const bankId = bankRound.bank.bankId; // Use human-readable bankId, not UUID
        const metrics = bankRound.metrics;
        
        bankMetrics[bankId] = {
          auc: metrics.auc,
          accuracy: metrics.accuracy,
          precision: metrics.precision,
          recall: metrics.recall,
          f1: metrics.f1,
          bank_id: bankId,
          num_samples: bankRound.samples || null,
          fraud_rate: bankRound.fraudRate || null,
          loss: metrics.loss || null,
          timestamp: metrics.timestamp.toISOString()
        };
      }
    }

    // CRITICAL: Response format must match Flutter expectation exactly
    const response = {
      round: trainingRound?.roundNumber || 0,
      bank_metrics: bankMetrics, // ✅ Must be 'bank_metrics', not 'banks'
      timestamp: trainingRound?.startedAt?.toISOString() || new Date().toISOString()
    };

    res.json(response);
  } catch (error) {
    logger.error('Get bank metrics error:', error);
    res.status(500).json({
      error: 'Internal Server Error',
      message: 'Failed to retrieve bank metrics',
      timestamp: new Date().toISOString()
    });
  }
};

/**
 * GET /api/metrics/banks/:bankId
 * Get metrics for a specific bank
 */
export const getBankMetricsById = async (req, res) => {
  try {
    const { bankId } = req.params;
    const roundNum = req.query.round_num ? parseInt(req.query.round_num) : null;

    // Find bank by human-readable bankId
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

    // Find training round (specific or latest) for this bank
    let trainingRound = null;
    let bankRound = null;
    
    if (roundNum) {
      // Get specific round and find bank's participation in it
      trainingRound = await prisma.trainingRound.findUnique({
        where: { roundNumber: roundNum },
        include: {
          bankRounds: {
            where: { bankId: bank.id }, // Use UUID for bankId field
            include: {
              metrics: true
            }
          }
        }
      });
      
      if (trainingRound && trainingRound.bankRounds.length > 0) {
        bankRound = trainingRound.bankRounds[0];
      }
    } else {
      // Get latest round for this bank
      bankRound = await prisma.bankTrainingRound.findFirst({
        where: { bankId: bank.id }, // Use UUID for bankId field
        orderBy: { createdAt: 'desc' },
        include: {
          metrics: true,
          round: true
        }
      });
      
      if (bankRound) {
        trainingRound = bankRound.round;
      }
    }

    if (!bankRound || !bankRound.metrics) {
      return res.status(404).json({
        error: 'Not Found',
        message: `No metrics found for bank ${bankId} in round ${roundNum || 'latest'}`,
        timestamp: new Date().toISOString()
      });
    }

    const metrics = bankRound.metrics;
    const roundNumber = trainingRound?.roundNumber || bankRound.round?.roundNumber || 0;

    // CRITICAL: Response format must match Flutter BankMetrics.fromJson() expectations
    const response = {
      bank_id: bankId,
      round: roundNumber,
      metrics: {
        auc: metrics.auc,
        accuracy: metrics.accuracy,
        precision: metrics.precision,
        recall: metrics.recall,
        f1: metrics.f1,
        bank_id: bankId,
        num_samples: bankRound.samples || null,
        fraud_rate: bankRound.fraudRate || null,
        loss: metrics.loss || null,
        timestamp: metrics.timestamp.toISOString()
      },
      timestamp: trainingRound?.startedAt?.toISOString() || bankRound.round?.startedAt?.toISOString() || new Date().toISOString()
    };

    res.json(response);
  } catch (error) {
    logger.error('Get bank metrics by ID error:', error);
    res.status(500).json({
      error: 'Internal Server Error',
      message: `Failed to retrieve metrics for bank ${req.params.bankId}`,
      timestamp: new Date().toISOString()
    });
  }
};

/**
 * GET /api/privacy
 * Flutter expects: { privacy_metrics: { current_epsilon, target_epsilon, delta, noise_multiplier, privacy_strength, budget_used_percentage } }
 */
export const getPrivacyMetrics = async (req, res) => {
  try {
    // Get latest privacy metrics from latest training round
    const latestRound = await prisma.trainingRound.findFirst({
      orderBy: { roundNumber: 'desc' },
      include: {
        privacyMetrics: true
      }
    });

    // If no rounds exist, return default privacy metrics
    if (!latestRound || !latestRound.privacyMetrics) {
      const defaultEpsilon = parseFloat(process.env.DEFAULT_EPSILON || '8.0');
      const defaultDelta = parseFloat(process.env.DEFAULT_DELTA || '0.00001');
      const defaultNoise = parseFloat(process.env.DEFAULT_NOISE_MULTIPLIER || '1.1');
      
      const privacyStrength = _calculatePrivacyStrength(defaultEpsilon);
      const budgetUsedPercentage = 0.0; // No training yet

      return res.json({
        privacy_metrics: {
          current_epsilon: defaultEpsilon,
          target_epsilon: defaultEpsilon,
          delta: defaultDelta,
          noise_multiplier: defaultNoise,
          privacy_strength: privacyStrength,
          budget_used_percentage: budgetUsedPercentage
        }
      });
    }

    const privacyMetrics = latestRound.privacyMetrics;

    // CRITICAL: Response format must match Flutter PrivacyMetrics.fromJson() expectations
    const response = {
      privacy_metrics: {
        current_epsilon: privacyMetrics.currentEpsilon,
        target_epsilon: privacyMetrics.targetEpsilon,
        delta: privacyMetrics.delta,
        noise_multiplier: privacyMetrics.noiseMultiplier,
        privacy_strength: privacyMetrics.privacyStrength,
        budget_used_percentage: privacyMetrics.budgetUsedPercentage
      }
    };

    res.json(response);
  } catch (error) {
    logger.error('Get privacy metrics error:', error);
    res.status(500).json({
      error: 'Internal Server Error',
      message: 'Failed to retrieve privacy metrics',
      timestamp: new Date().toISOString()
    });
  }
};

/**
 * GET /api/rounds?limit=50&offset=0
 * Flutter expects: { rounds: [{ round, global_metrics, client_metrics, privacy_metrics?, timestamp, duration? }], total?, limit?, offset? }
 */
export const getTrainingRounds = async (req, res) => {
  try {
    const limit = parseInt(req.query.limit) || 50;
    const offset = parseInt(req.query.offset) || 0;

    // Validate pagination parameters
    if (limit < 1 || limit > 1000) {
      return res.status(400).json({
        error: 'Bad Request',
        message: 'Limit must be between 1 and 1000',
        timestamp: new Date().toISOString()
      });
    }

    if (offset < 0) {
      return res.status(400).json({
        error: 'Bad Request',
        message: 'Offset must be non-negative',
        timestamp: new Date().toISOString()
      });
    }

    // Get total count for pagination metadata
    const total = await prisma.trainingRound.count();

    // Fetch training rounds with pagination
    const trainingRounds = await prisma.trainingRound.findMany({
      orderBy: { roundNumber: 'desc' },
      skip: offset,
      take: limit,
      include: {
        globalMetrics: true,
        privacyMetrics: true,
        bankRounds: {
          include: {
            bank: true,
            metrics: true
          }
        }
      }
    });

    // Transform to Flutter TrainingRound.fromJson() format
    const rounds = trainingRounds.map(round => {
      // Build client_metrics map (bankId -> BankMetrics)
      const clientMetrics = {};
      for (const bankRound of round.bankRounds) {
        const bankId = bankRound.bank.bankId; // Use human-readable bankId
        const metrics = bankRound.metrics;
        
        clientMetrics[bankId] = {
          auc: metrics.auc,
          accuracy: metrics.accuracy,
          precision: metrics.precision,
          recall: metrics.recall,
          f1: metrics.f1,
          bank_id: bankId,
          num_samples: bankRound.samples || null,
          fraud_rate: bankRound.fraudRate || null,
          loss: metrics.loss || null,
          timestamp: metrics.timestamp.toISOString()
        };
      }

      // Build global_metrics
      const globalMetrics = {
        auc: round.globalMetrics.auc,
        accuracy: round.globalMetrics.accuracy,
        precision: round.globalMetrics.precision,
        recall: round.globalMetrics.recall,
        f1: round.globalMetrics.f1,
        loss: round.globalMetrics.loss || null,
        ...(round.globalMetrics.specificity !== null && { 
          specificity: round.globalMetrics.specificity 
        })
      };

      // Build privacy_metrics (optional)
      let privacyMetrics = null;
      if (round.privacyMetrics) {
        privacyMetrics = {
          current_epsilon: round.privacyMetrics.currentEpsilon,
          target_epsilon: round.privacyMetrics.targetEpsilon,
          delta: round.privacyMetrics.delta,
          noise_multiplier: round.privacyMetrics.noiseMultiplier,
          privacy_strength: round.privacyMetrics.privacyStrength,
          budget_used_percentage: round.privacyMetrics.budgetUsedPercentage
        };
      }

      // Calculate duration if available
      let duration = null;
      if (round.completedAt && round.startedAt) {
        duration = (round.completedAt.getTime() - round.startedAt.getTime()) / 1000; // seconds
      }

      // CRITICAL: Format must match Flutter TrainingRound.fromJson() expectations
      return {
        round: round.roundNumber,
        global_metrics: globalMetrics,
        client_metrics: clientMetrics, // Map<String, BankMetrics>
        ...(privacyMetrics && { privacy_metrics: privacyMetrics }),
        timestamp: round.startedAt.toISOString(), // ✅ ISO string, not DateTime
        ...(duration !== null && { duration: duration })
      };
    });

    // CRITICAL: Response must have 'rounds' array key
    const response = {
      rounds: rounds,
      total: total,
      limit: limit,
      offset: offset
    };

    res.json(response);
  } catch (error) {
    logger.error('Get training rounds error:', error);
    res.status(500).json({
      error: 'Internal Server Error',
      message: 'Failed to retrieve training rounds',
      timestamp: new Date().toISOString()
    });
  }
};

/**
 * Helper function to calculate privacy strength string
 */
function _calculatePrivacyStrength(epsilon) {
  if (epsilon <= 1.0) return 'Very Strong';
  if (epsilon <= 3.0) return 'Strong';
  if (epsilon <= 8.0) return 'Moderate';
  if (epsilon <= 15.0) return 'Weak';
  return 'Very Weak';
}
