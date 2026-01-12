/**
 * Training Results Validation Schemas
 * Zod schemas for training endpoints
 */

import { z } from 'zod';

// Metrics schema (reusable)
const metricsSchema = z.object({
  auc: z.number().min(0).max(1),
  accuracy: z.number().min(0).max(1),
  precision: z.number().min(0).max(1),
  recall: z.number().min(0).max(1),
  f1: z.number().min(0).max(1),
  loss: z.number().optional().nullable(),
  specificity: z.number().min(0).max(1).optional().nullable()
});

// Bank metrics schema
const bankMetricsSchema = z.record(
  z.string(), // bankId
  metricsSchema.extend({
    num_samples: z.number().int().positive().optional().nullable(),
    fraud_rate: z.number().min(0).max(1).optional().nullable()
  })
);

// Privacy metrics schema
const privacyMetricsSchema = z.object({
  current_epsilon: z.number().min(0),
  target_epsilon: z.number().min(0),
  delta: z.number().min(0).max(1),
  noise_multiplier: z.number().min(0),
  privacy_strength: z.string().optional(),
  budget_used_percentage: z.number().min(0).max(100)
});

// Single training round schema
export const storeTrainingRoundSchema = z.object({
  body: z.object({
    round: z.number().int().positive(),
    global_metrics: metricsSchema,
    client_metrics: bankMetricsSchema.optional(), // Also accepts bank_metrics
    bank_metrics: bankMetricsSchema.optional(), // Alias for client_metrics
    privacy_metrics: privacyMetricsSchema.optional(),
    timestamp: z.union([z.string().datetime(), z.date()]).optional(),
    duration: z.number().positive().optional().nullable()
  })
});

// Batch training rounds schema (array of rounds)
export const storeTrainingRoundsBatchSchema = z.object({
  body: z.union([
    z.array(storeTrainingRoundSchema.shape.body), // Array of rounds
    z.object({
      rounds: z.array(storeTrainingRoundSchema.shape.body) // Wrapped in "rounds" key
    })
  ])
});

// Sync training results schema
export const syncTrainingResultsSchema = z.object({
  body: z.object({
    results: z.object({
      history: z.array(storeTrainingRoundSchema.shape.body).optional(),
      rounds: z.array(storeTrainingRoundSchema.shape.body).optional()
    }).optional(),
    file_path: z.string().optional()
  }).refine(data => data.results || data.file_path, {
    message: 'Either "results" or "file_path" must be provided'
  })
});
