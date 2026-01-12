/**
 * Training Results Controller
 * Handles storing training results from Python training scripts
 */

import prisma from '../utils/prisma.js';
import { logger } from '../utils/logger.js';

/**
 * POST /api/training/rounds
 * Store a single training round's results
 * Called by Python training scripts after each round or at the end
 */
export const storeTrainingRound = async (req, res) => {
  try {
    const {
      round,
      global_metrics,
      client_metrics, // Also accepts bank_metrics for compatibility
      privacy_metrics,
      timestamp,
      duration
    } = req.body;

    // Check if round already exists
    const existingRound = await prisma.trainingRound.findUnique({
      where: { roundNumber: round }
    });

    if (existingRound) {
      return res.status(409).json({
        error: 'Conflict',
        message: `Round ${round} already exists`,
        timestamp: new Date().toISOString()
      });
    }

    // Create global metrics
    const globalMetrics = await prisma.classificationMetrics.create({
      data: {
        auc: parseFloat(global_metrics.auc || 0.0),
        accuracy: parseFloat(global_metrics.accuracy || 0.0),
        precision: parseFloat(global_metrics.precision || 0.0),
        recall: parseFloat(global_metrics.recall || 0.0),
        f1: parseFloat(global_metrics.f1 || 0.0),
        loss: global_metrics.loss !== null && global_metrics.loss !== undefined ? parseFloat(global_metrics.loss) : null,
        specificity: global_metrics.specificity !== null && global_metrics.specificity !== undefined ? parseFloat(global_metrics.specificity) : null
      }
    });

    // Parse timestamp
    let startedAt = new Date();
    let completedAt = null;

    if (timestamp) {
      if (typeof timestamp === 'string') {
        startedAt = new Date(timestamp);
        completedAt = duration ? new Date(new Date(timestamp).getTime() + duration * 1000) : startedAt;
      } else if (timestamp instanceof Date) {
        startedAt = timestamp;
        completedAt = duration ? new Date(timestamp.getTime() + duration * 1000) : startedAt;
      }
    }

    // Create training round
    const trainingRound = await prisma.trainingRound.create({
      data: {
        roundNumber: round,
        status: 'COMPLETED',
        globalMetricsId: globalMetrics.id,
        startedAt: startedAt,
        completedAt: completedAt,
        duration: duration ? parseFloat(duration) : null
      }
    });

    // Store bank/client metrics
    const bankMetricsData = client_metrics || req.body.bank_metrics || {};
    const bankMetricsCreated = [];

    for (const [bankId, bankMetrics] of Object.entries(bankMetricsData)) {
      try {
        // Find bank by human-readable bankId
        const bank = await prisma.bank.findUnique({
          where: { bankId: bankId }
        });

        if (!bank) {
          logger.warn(`Bank ${bankId} not found in database, skipping bank metrics for round ${round}`);
          continue;
        }

        // Create classification metrics for this bank
        const bankClassificationMetrics = await prisma.classificationMetrics.create({
          data: {
            auc: parseFloat(bankMetrics.auc || 0.0),
            accuracy: parseFloat(bankMetrics.accuracy || 0.0),
            precision: parseFloat(bankMetrics.precision || 0.0),
            recall: parseFloat(bankMetrics.recall || 0.0),
            f1: parseFloat(bankMetrics.f1 || 0.0),
            loss: bankMetrics.loss !== null && bankMetrics.loss !== undefined ? parseFloat(bankMetrics.loss) : null
          }
        });

        // Create bank training round record
        await prisma.bankTrainingRound.create({
          data: {
            roundId: trainingRound.id,
            bankId: bank.id, // Use UUID
            metricsId: bankClassificationMetrics.id,
            samples: bankMetrics.num_samples !== null && bankMetrics.num_samples !== undefined ? parseInt(bankMetrics.num_samples) : null,
            fraudRate: bankMetrics.fraud_rate !== null && bankMetrics.fraud_rate !== undefined ? parseFloat(bankMetrics.fraud_rate) : null
          }
        });

        bankMetricsCreated.push(bankId);
      } catch (bankError) {
        logger.error(`Error creating metrics for bank ${bankId} in round ${round}:`, bankError);
        // Continue with other banks
      }
    }

    // Store privacy metrics if available
    let privacyMetricsId = null;
    if (privacy_metrics) {
      try {
        const privacyMetrics = await prisma.privacyMetrics.create({
          data: {
            currentEpsilon: parseFloat(privacy_metrics.current_epsilon || 0.0),
            targetEpsilon: parseFloat(privacy_metrics.target_epsilon || 8.0),
            delta: parseFloat(privacy_metrics.delta || 1e-5),
            noiseMultiplier: parseFloat(privacy_metrics.noise_multiplier || 1.1),
            privacyStrength: String(privacy_metrics.privacy_strength || 'Moderate'),
            budgetUsedPercentage: parseFloat(privacy_metrics.budget_used_percentage || 0.0)
          }
        });

        privacyMetricsId = privacyMetrics.id;

        // Link privacy metrics to training round
        await prisma.trainingRound.update({
          where: { id: trainingRound.id },
          data: { privacyMetricsId: privacyMetrics.id }
        });
      } catch (privacyError) {
        logger.error(`Error creating privacy metrics for round ${round}:`, privacyError);
        // Continue without privacy metrics
      }
    }

    logger.info(`Training round ${round} stored successfully`, {
      round,
      banks_synced: bankMetricsCreated.length,
      has_privacy: !!privacyMetricsId
    });

    res.status(201).json({
      message: 'Training round stored successfully',
      round: round,
      training_round_id: trainingRound.id,
      banks_synced: bankMetricsCreated,
      banks_count: bankMetricsCreated.length,
      has_privacy_metrics: !!privacyMetricsId,
      timestamp: new Date().toISOString()
    });
  } catch (error) {
    logger.error('Store training round error:', error);
    res.status(500).json({
      error: 'Internal Server Error',
      message: 'Failed to store training round',
      details: process.env.NODE_ENV === 'development' ? error.message : undefined,
      timestamp: new Date().toISOString()
    });
  }
};

/**
 * POST /api/training/rounds/batch
 * Store multiple training rounds at once
 */
export const storeTrainingRoundsBatch = async (req, res) => {
  try {
    const rounds = Array.isArray(req.body) ? req.body : req.body.rounds || [];

    if (!rounds || rounds.length === 0) {
      return res.status(400).json({
        error: 'Bad Request',
        message: 'No training rounds provided',
        timestamp: new Date().toISOString()
      });
    }

    if (rounds.length > 100) {
      return res.status(400).json({
        error: 'Bad Request',
        message: 'Batch size cannot exceed 100 rounds',
        timestamp: new Date().toISOString()
      });
    }

    const results = {
      successful: [],
      failed: [],
      skipped: []
    };

    // Process each round sequentially to avoid database conflicts
    for (const roundData of rounds) {
      try {
        const round = roundData.round;

        // Check if round already exists
        const existingRound = await prisma.trainingRound.findUnique({
          where: { roundNumber: round }
        });

        if (existingRound) {
          results.skipped.push({ round, reason: 'Already exists' });
          continue;
        }

        // Create global metrics
        const globalMetrics = await prisma.classificationMetrics.create({
          data: {
            auc: parseFloat(roundData.global_metrics?.auc || 0.0),
            accuracy: parseFloat(roundData.global_metrics?.accuracy || 0.0),
            precision: parseFloat(roundData.global_metrics?.precision || 0.0),
            recall: parseFloat(roundData.global_metrics?.recall || 0.0),
            f1: parseFloat(roundData.global_metrics?.f1 || 0.0),
            loss: roundData.global_metrics?.loss !== null && roundData.global_metrics?.loss !== undefined ? parseFloat(roundData.global_metrics.loss) : null,
            specificity: roundData.global_metrics?.specificity !== null && roundData.global_metrics?.specificity !== undefined ? parseFloat(roundData.global_metrics.specificity) : null
          }
        });

        // Parse timestamp
        let startedAt = new Date();
        let completedAt = null;

        if (roundData.timestamp) {
          if (typeof roundData.timestamp === 'string') {
            startedAt = new Date(roundData.timestamp);
            completedAt = roundData.duration ? new Date(new Date(roundData.timestamp).getTime() + roundData.duration * 1000) : startedAt;
          } else if (roundData.timestamp instanceof Date) {
            startedAt = roundData.timestamp;
            completedAt = roundData.duration ? new Date(roundData.timestamp.getTime() + roundData.duration * 1000) : startedAt;
          }
        }

        // Create training round
        const trainingRound = await prisma.trainingRound.create({
          data: {
            roundNumber: round,
            status: 'COMPLETED',
            globalMetricsId: globalMetrics.id,
            startedAt: startedAt,
            completedAt: completedAt,
            duration: roundData.duration ? parseFloat(roundData.duration) : null
          }
        });

        // Store bank metrics
        const bankMetricsData = roundData.client_metrics || roundData.bank_metrics || {};
        let banksSynced = 0;

        for (const [bankId, bankMetrics] of Object.entries(bankMetricsData)) {
          try {
            const bank = await prisma.bank.findUnique({
              where: { bankId: bankId }
            });

            if (!bank) {
              logger.warn(`Bank ${bankId} not found for round ${round}`);
              continue;
            }

            const bankClassificationMetrics = await prisma.classificationMetrics.create({
              data: {
                auc: parseFloat(bankMetrics.auc || 0.0),
                accuracy: parseFloat(bankMetrics.accuracy || 0.0),
                precision: parseFloat(bankMetrics.precision || 0.0),
                recall: parseFloat(bankMetrics.recall || 0.0),
                f1: parseFloat(bankMetrics.f1 || 0.0),
                loss: bankMetrics.loss !== null && bankMetrics.loss !== undefined ? parseFloat(bankMetrics.loss) : null
              }
            });

            await prisma.bankTrainingRound.create({
              data: {
                roundId: trainingRound.id,
                bankId: bank.id,
                metricsId: bankClassificationMetrics.id,
                samples: bankMetrics.num_samples !== null && bankMetrics.num_samples !== undefined ? parseInt(bankMetrics.num_samples) : null,
                fraudRate: bankMetrics.fraud_rate !== null && bankMetrics.fraud_rate !== undefined ? parseFloat(bankMetrics.fraud_rate) : null
              }
            });

            banksSynced++;
          } catch (bankError) {
            logger.error(`Error creating bank metrics for ${bankId} in round ${round}:`, bankError);
          }
        }

        // Store privacy metrics if available
        if (roundData.privacy_metrics) {
          try {
            const privacyMetrics = await prisma.privacyMetrics.create({
              data: {
                currentEpsilon: parseFloat(roundData.privacy_metrics.current_epsilon || 0.0),
                targetEpsilon: parseFloat(roundData.privacy_metrics.target_epsilon || 8.0),
                delta: parseFloat(roundData.privacy_metrics.delta || 1e-5),
                noiseMultiplier: parseFloat(roundData.privacy_metrics.noise_multiplier || 1.1),
                privacyStrength: String(roundData.privacy_metrics.privacy_strength || 'Moderate'),
                budgetUsedPercentage: parseFloat(roundData.privacy_metrics.budget_used_percentage || 0.0)
              }
            });

            await prisma.trainingRound.update({
              where: { id: trainingRound.id },
              data: { privacyMetricsId: privacyMetrics.id }
            });
          } catch (privacyError) {
            logger.error(`Error creating privacy metrics for round ${round}:`, privacyError);
          }
        }

        results.successful.push({ round, banks_synced: banksSynced });
      } catch (roundError) {
        logger.error(`Error storing round ${roundData.round}:`, roundError);
        results.failed.push({
          round: roundData.round,
          error: roundError.message
        });
      }
    }

    res.status(201).json({
      message: 'Batch training rounds processed',
      total: rounds.length,
      successful: results.successful.length,
      failed: results.failed.length,
      skipped: results.skipped.length,
      results: results,
      timestamp: new Date().toISOString()
    });
  } catch (error) {
    logger.error('Store training rounds batch error:', error);
    res.status(500).json({
      error: 'Internal Server Error',
      message: 'Failed to store training rounds batch',
      details: process.env.NODE_ENV === 'development' ? error.message : undefined,
      timestamp: new Date().toISOString()
    });
  }
};

/**
 * POST /api/training/sync
 * Convenience endpoint that accepts a file path or JSON data
 * and syncs all training results
 */
export const syncTrainingResults = async (req, res) => {
  try {
    const { results, file_path } = req.body;

    if (!results && !file_path) {
      return res.status(400).json({
        error: 'Bad Request',
        message: 'Either "results" (JSON data) or "file_path" (path to JSON file) is required',
        timestamp: new Date().toISOString()
      });
    }

    // If file_path provided, would need to read file (but this is API, so prefer JSON data)
    // For security, we'll only accept JSON data directly
    if (file_path) {
      return res.status(400).json({
        error: 'Bad Request',
        message: 'File path not supported. Please send JSON data directly in "results" field.',
        timestamp: new Date().toISOString()
      });
    }

    // Extract rounds from results
    const history = results.history || results.rounds || [];
    
    if (!Array.isArray(history) || history.length === 0) {
      return res.status(400).json({
        error: 'Bad Request',
        message: 'No training rounds found in results. Expected "history" or "rounds" array.',
        timestamp: new Date().toISOString()
      });
    }

    // Use batch endpoint logic
    // Call the batch handler logic here (reuse code)
    req.body = history;
    return await storeTrainingRoundsBatch(req, res);

  } catch (error) {
    logger.error('Sync training results error:', error);
    res.status(500).json({
      error: 'Internal Server Error',
      message: 'Failed to sync training results',
      details: process.env.NODE_ENV === 'development' ? error.message : undefined,
      timestamp: new Date().toISOString()
    });
  }
};
