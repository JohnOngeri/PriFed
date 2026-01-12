/**
 * Bank Management Validation Schemas
 */

import { z } from 'zod';

// Create bank schema
export const createBankSchema = z.object({
  body: z.object({
    bankId: z.string().min(1, 'Bank ID is required'),
    name: z.string().min(1, 'Bank name is required'),
    subtitle: z.string().optional(),
    color: z.string().default('blue'),
    icon: z.string().default('building_modern')
  })
});

// Update bank schema
export const updateBankSchema = z.object({
  body: z.object({
    name: z.string().min(1).optional(),
    subtitle: z.string().optional(),
    color: z.string().optional(),
    icon: z.string().optional(),
    isActive: z.boolean().optional()
  }),
  params: z.object({
    bankId: z.string().min(1, 'Bank ID is required')
  })
});

// Create bank application schema
export const createBankApplicationSchema = z.object({
  body: z.object({
    bankId: z.string().min(1, 'Bank ID is required'),
    bankName: z.string().min(1, 'Bank name is required'),
    licenseNumber: z.string().min(1, 'License number is required'),
    contactEmail: z.string().email('Invalid email address'),
    contactPhone: z.string().min(1, 'Contact phone is required'),
    address: z.string().min(1, 'Address is required')
  })
});

// Vote on application schema
export const voteOnApplicationSchema = z.object({
  body: z.object({
    vote: z.enum(['APPROVE', 'REJECT'], {
      errorMap: () => ({ message: 'Vote must be either APPROVE or REJECT' })
    })
  }),
  params: z.object({
    applicationId: z.string().min(1, 'Application ID is required')
  })
});
