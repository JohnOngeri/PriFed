/**
 * Health Check Controller
 * System health monitoring
 */

import prisma from '../utils/prisma.js';
import { logger } from '../utils/logger.js';

/**
 * Health check endpoint
 * P0 FIX: Always returns 200 with DB status, prevents timeout
 */
export const healthCheck = async (req, res) => {
  try {
    const startTime = Date.now();

    // Check database connection with timeout protection
    let dbHealthy = false;
    let dbError = null;
    try {
      // Set timeout for database query (2 seconds max)
      const dbCheckPromise = prisma.$queryRaw`SELECT 1`;
      const timeoutPromise = new Promise((_, reject) => 
        setTimeout(() => reject(new Error('Database query timeout')), 2000)
      );
      
      await Promise.race([dbCheckPromise, timeoutPromise]);
      dbHealthy = true;
    } catch (error) {
      dbError = error.message;
      logger.error('Database health check failed:', error);
    }

    const uptime = process.uptime();
    const healthStatus = dbHealthy ? 'healthy' : 'degraded';

    const response = {
      status: healthStatus,
      version: '1.0.0',
      uptime_seconds: uptime,
      component_checks: {
        api: true,
        database: dbHealthy,
        ...(dbError && { database_error: dbError }),
        timestamp: new Date().toISOString()
      },
      timestamp: new Date().toISOString()
    };

    // P0 FIX: Always return 200 even if DB is down (per requirements)
    res.status(200).json(response);
  } catch (error) {
    logger.error('Health check error:', error);
    // Even on unexpected errors, return 200 with error details
    res.status(200).json({
      status: 'unhealthy',
      version: '1.0.0',
      error: error.message,
      component_checks: {
        api: false,
        database: false,
        timestamp: new Date().toISOString()
      },
      timestamp: new Date().toISOString()
    });
  }
};
