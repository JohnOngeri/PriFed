/**
 * Fraud Detection Validation Schemas
 */

import { z } from 'zod';

// Fraud prediction schema
export const predictFraudSchema = z.object({
  body: z.object({
    transaction_features: z.record(z.any()).refine(
      data => Object.keys(data).length > 0,
      { message: 'Transaction features are required' }
    )
  })
});
