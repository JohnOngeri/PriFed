/**
 * Fraud Detection Controller
 * Transaction fraud prediction
 * CRITICAL: Response must match Flutter FraudTransaction.fromJson() expectations exactly
 */

import prisma from '../utils/prisma.js';
import { logger } from '../utils/logger.js';

/**
 * POST /api/fraud/predict
 * Flutter expects: FraudTransaction object directly (not nested)
 * Request: { transaction_features: { ... } }
 * Response: { id, amount, timestamp, fraud_probability, risk_level, features, risk_factors, bank_predictions }
 */
export const predictFraud = async (req, res) => {
  try {
    const { transaction_features } = req.body;

    if (!transaction_features || typeof transaction_features !== 'object') {
      return res.status(400).json({
        error: 'Bad Request',
        message: 'transaction_features is required and must be an object',
        timestamp: new Date().toISOString()
      });
    }

    // Extract amount from features (if present)
    const amount = transaction_features.amount || transaction_features.transaction_amount || 0.0;

    // TODO: Integrate with actual fraud detection model
    // For now, use mock prediction logic based on features
    const fraudProbability = _calculateFraudProbability(transaction_features);

    // Determine risk level
    let riskLevel = 'LOW';
    if (fraudProbability > 0.7) {
      riskLevel = 'HIGH';
    } else if (fraudProbability > 0.3) {
      riskLevel = 'MEDIUM';
    }

    // Determine risk factors
    const riskFactors = _determineRiskFactors(transaction_features, fraudProbability);

    // Get bank predictions (mock for now - would call actual bank models)
    const bankPredictions = await _getBankPredictions(transaction_features, fraudProbability);

    // Generate transaction ID
    const transactionId = `TXN_${Date.now()}_${Math.floor(Math.random() * 10000)}`;

    // Store prediction in database (optional - for audit/logging)
    try {
      if (req.user?.bankId) {
        // Get bank UUID from bankId
        const bank = await prisma.bank.findUnique({
          where: { bankId: req.user.bankId }
        });

        if (bank) {
          await prisma.fraudTransaction.create({
            data: {
              transactionId: transactionId,
              bankId: bank.id,
              amount: amount,
              fraudProbability: fraudProbability,
              riskLevel: riskLevel,
              features: transaction_features,
              riskFactors: riskFactors,
              bankPredictions: bankPredictions
            }
          });
        }
      }
    } catch (dbError) {
      // Log but don't fail the request if DB write fails
      logger.warn('Failed to store fraud prediction in database:', dbError);
    }

    // CRITICAL: Response format must match Flutter FraudTransaction.fromJson() expectations exactly
    const response = {
      id: transactionId,
      amount: amount,
      timestamp: new Date().toISOString(), // ✅ ISO string
      fraud_probability: fraudProbability,
      risk_level: riskLevel, // ✅ "High", "Medium", "Low" (matches enum)
      features: transaction_features,
      risk_factors: riskFactors, // ✅ Array of strings
      bank_predictions: bankPredictions // ✅ Map<String, double>
    };

    res.json(response);
  } catch (error) {
    logger.error('Predict fraud error:', error);
    res.status(500).json({
      error: 'Internal Server Error',
      message: 'Failed to predict fraud',
      timestamp: new Date().toISOString()
    });
  }
};

/**
 * POST /api/fraud/predict/batch
 * Batch fraud prediction (requires authentication)
 */
export const predictFraudBatch = async (req, res) => {
  try {
    const { transactions } = req.body;

    if (!Array.isArray(transactions) || transactions.length === 0) {
      return res.status(400).json({
        error: 'Bad Request',
        message: 'transactions must be a non-empty array',
        timestamp: new Date().toISOString()
      });
    }

    if (transactions.length > 100) {
      return res.status(400).json({
        error: 'Bad Request',
        message: 'Batch size cannot exceed 100 transactions',
        timestamp: new Date().toISOString()
      });
    }

    // Process all transactions
    const predictions = [];
    for (const transactionFeatures of transactions) {
      const amount = transactionFeatures.amount || transactionFeatures.transaction_amount || 0.0;
      const fraudProbability = _calculateFraudProbability(transactionFeatures);
      
      let riskLevel = 'LOW';
      if (fraudProbability > 0.7) {
        riskLevel = 'HIGH';
      } else if (fraudProbability > 0.3) {
        riskLevel = 'MEDIUM';
      }

      const riskFactors = _determineRiskFactors(transactionFeatures, fraudProbability);
      const bankPredictions = await _getBankPredictions(transactionFeatures, fraudProbability);
      const transactionId = `TXN_${Date.now()}_${Math.floor(Math.random() * 10000)}`;

      predictions.push({
        id: transactionId,
        amount: amount,
        timestamp: new Date().toISOString(),
        fraud_probability: fraudProbability,
        risk_level: riskLevel,
        features: transactionFeatures,
        risk_factors: riskFactors,
        bank_predictions: bankPredictions
      });
    }

    res.json(predictions);
  } catch (error) {
    logger.error('Batch fraud prediction error:', error);
    res.status(500).json({
      error: 'Internal Server Error',
      message: 'Failed to predict fraud for batch',
      timestamp: new Date().toISOString()
    });
  }
};

/**
 * Calculate fraud probability based on transaction features
 * TODO: Replace with actual ML model inference
 */
function _calculateFraudProbability(features) {
  // Mock fraud detection logic
  let score = 0.1; // Base probability

  // Card not present increases risk
  if (features.card_present === false) {
    score += 0.15;
  }

  // Foreign location increases risk
  if (features.location && typeof features.location === 'string') {
    const highRiskLocations = ['Nigeria', 'Russia', 'China', 'Lagos', 'Moscow'];
    if (highRiskLocations.some(loc => features.location.includes(loc))) {
      score += 0.20;
    }
  }

  // New device increases risk
  if (features.device_age && features.device_age < 30) {
    score += 0.10;
  }

  // High-risk merchant category
  if (features.merchant_category) {
    const highRiskCategories = ['Online Retail', 'Digital Goods', 'Gambling'];
    if (highRiskCategories.includes(features.merchant_category)) {
      score += 0.15;
    }
  }

  // Unusual amount
  if (features.amount) {
    if (features.amount > 5000) {
      score += 0.10;
    }
    if (features.amount > 10000) {
      score += 0.10;
    }
  }

  // Unusual time (night transactions)
  if (features.hour && (features.hour < 6 || features.hour > 23)) {
    score += 0.05;
  }

  // Transaction velocity (multiple transactions in short time)
  if (features.transaction_count && features.transaction_count > 5) {
    score += 0.10;
  }

  // Cap at 0.99 maximum
  return Math.min(score, 0.99);
}

/**
 * Determine risk factors based on features and probability
 */
function _determineRiskFactors(features, fraudProbability) {
  const factors = [];

  if (fraudProbability > 0.7) {
    if (features.card_present === false) {
      factors.push('Card not present');
    }
    if (features.location && typeof features.location === 'string') {
      const highRiskLocations = ['Nigeria', 'Russia', 'China'];
      if (highRiskLocations.some(loc => features.location.includes(loc))) {
        factors.push('Foreign transaction');
        factors.push('High-risk location');
      }
    }
    if (features.amount && features.amount > 5000) {
      factors.push('Unusual amount');
    }
    if (features.device_age && features.device_age < 30) {
      factors.push('New device');
    }
    if (features.merchant_category && ['Online Retail', 'Digital Goods'].includes(features.merchant_category)) {
      factors.push('High-risk merchant');
    }
  } else if (fraudProbability > 0.3) {
    if (features.hour && (features.hour < 6 || features.hour > 23)) {
      factors.push('Unusual time');
    }
    if (features.transaction_count && features.transaction_count > 3) {
      factors.push('Multiple recent transactions');
    }
  }

  return factors.length > 0 ? factors : [];
}

/**
 * Get bank predictions (mock - would call actual bank models)
 */
async function _getBankPredictions(transactionFeatures, baseProbability) {
  try {
    // Get all active banks
    const banks = await prisma.bank.findMany({
      where: { isActive: true },
      select: { bankId: true }
    });

    // Mock bank predictions (slight variations from base probability)
    const predictions = {};
    for (const bank of banks) {
      // Add small random variation to base probability
      const variation = (Math.random() - 0.5) * 0.05; // ±2.5%
      predictions[bank.bankId] = Math.max(0, Math.min(1, baseProbability + variation));
    }

    return predictions;
  } catch (error) {
    logger.error('Failed to get bank predictions:', error);
    // Return empty predictions if database query fails
    return {};
  }
}
