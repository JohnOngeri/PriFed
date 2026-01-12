/**
 * Prisma Client Singleton
 * Ensures single instance across the application
 */

import { PrismaClient } from '@prisma/client';
import { logger } from './logger.js';

// Create Prisma Client instance
const prisma = new PrismaClient({
  log: process.env.NODE_ENV === 'development' 
    ? ['query', 'info', 'warn', 'error']
    : ['error'],
  errorFormat: 'pretty'
});

// Handle Prisma connection events (optional - only in development)
if (process.env.NODE_ENV === 'development') {
  // Query logging is handled by Prisma log configuration above
}

// Graceful shutdown
process.on('beforeExit', async () => {
  await prisma.$disconnect();
  logger.info('Prisma client disconnected');
});

// Error handling middleware (Prisma middleware is not available in newer versions)
// Logging is handled by Prisma's built-in logging

export default prisma;
