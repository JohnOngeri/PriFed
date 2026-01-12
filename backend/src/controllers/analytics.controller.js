/**
 * Analytics Controller
 * Fairness analysis and advanced analytics
 * CRITICAL: Response must match Flutter expectations
 */

import prisma from '../utils/prisma.js';
import { logger } from '../utils/logger.js';

/**
 * GET /api/analytics/fairness
 * Flutter expects: { fairness_score, auc_variance, max_auc_difference, assessment }
 */
export const getFairnessAnalysis = async (req, res) => {
  try {
    // Get latest metrics for all banks
    const latestRound = await prisma.trainingRound.findFirst({
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

    if (!latestRound || latestRound.bankRounds.length === 0) {
      return res.json({
        fairness_score: 1.0,
        auc_variance: 0.0,
        max_auc_difference: 0.0,
        assessment: 'No data available',
        bank_count: 0,
        timestamp: new Date().toISOString()
      });
    }

    // Extract AUC values for all banks
    const aucs = latestRound.bankRounds.map(br => br.metrics.auc);
    
    // Calculate fairness metrics
    const meanAuc = aucs.reduce((sum, auc) => sum + auc, 0) / aucs.length;
    const variance = aucs.reduce((sum, auc) => sum + Math.pow(auc - meanAuc, 2), 0) / aucs.length;
    const maxAuc = Math.max(...aucs);
    const minAuc = Math.min(...aucs);
    const maxAucDifference = maxAuc - minAuc;

    // Calculate fairness score (1.0 = perfect fairness, 0.0 = worst)
    // Lower variance and smaller max difference = higher fairness
    const fairnessScore = Math.max(0, Math.min(1, 1 - (variance * 100) - (maxAucDifference * 10)));

    // Determine assessment
    let assessment = 'Poor';
    if (fairnessScore >= 0.9) {
      assessment = 'Excellent';
    } else if (fairnessScore >= 0.75) {
      assessment = 'Good';
    } else if (fairnessScore >= 0.5) {
      assessment = 'Fair';
    }

    // CRITICAL: Response format must match Flutter expectation
    const response = {
      fairness_score: fairnessScore,
      auc_variance: variance,
      max_auc_difference: maxAucDifference,
      assessment: assessment,
      bank_count: latestRound.bankRounds.length,
      bank_aucs: latestRound.bankRounds.reduce((acc, br) => {
        acc[br.bank.bankId] = br.metrics.auc;
        return acc;
      }, {}),
      timestamp: new Date().toISOString()
    };

    res.json(response);
  } catch (error) {
    logger.error('Get fairness analysis error:', error);
    res.status(500).json({
      error: 'Internal Server Error',
      message: 'Failed to retrieve fairness analysis',
      timestamp: new Date().toISOString()
    });
  }
};
