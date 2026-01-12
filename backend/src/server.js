/**
 * PrivFed Mobile Backend - Main Server
 * Node.js + Express + PostgreSQL + Prisma
 */

import express from 'express';
import cors from 'cors';
import helmet from 'helmet';
import dotenv from 'dotenv';
import { logger } from './utils/logger.js';
import { errorHandler } from './middleware/errorHandler.js';
import { requestLogger } from './middleware/requestLogger.js';

// Load environment variables
dotenv.config();

// Import routes
import authRoutes from './routes/auth.routes.js';
import healthRoutes from './routes/health.routes.js';
import statusRoutes from './routes/status.routes.js';
import metricsRoutes from './routes/metrics.routes.js';
import privacyRoutes from './routes/privacy.routes.js';
import roundsRoutes from './routes/rounds.routes.js';
import fraudRoutes from './routes/fraud.routes.js';
import bankRoutes from './routes/bank.routes.js';
import analyticsRoutes from './routes/analytics.routes.js';
import datasetRoutes from './routes/dataset.routes.js';
import trainingRoutes from './routes/training.routes.js';

const app = express();
const PORT = process.env.PORT || 8000;

// ============================================
// MIDDLEWARE
// ============================================

// Security middleware
app.use(helmet({
  contentSecurityPolicy: false, // Allow for mobile app flexibility
  crossOriginResourcePolicy: { policy: "cross-origin" }
}));

// CORS configuration - Mobile optimized
// P1 FIX: Allow mobile apps (no origin) and configured web origins
const corsOptions = {
  origin: (origin, callback) => {
    // Allow requests with no origin (mobile apps, Postman, curl)
    if (!origin) {
      callback(null, true);
      return;
    }
    
    // Allow configured origins
    const allowedOrigins = process.env.CORS_ORIGIN?.split(',') || [
      'http://localhost:3000',
      'http://localhost:8080',
      'http://localhost:8000'
    ];
    
    if (allowedOrigins.includes(origin)) {
      callback(null, true);
    } else {
      callback(new Error('Not allowed by CORS'));
    }
  },
  credentials: true,
  methods: ['GET', 'POST', 'PUT', 'DELETE', 'PATCH', 'OPTIONS'],
  allowedHeaders: ['Content-Type', 'Authorization', 'X-Requested-With', 'X-Retry'],
  exposedHeaders: ['X-Process-Time', 'X-Total-Count']
};

app.use(cors(corsOptions));

// Body parsing
app.use(express.json({ limit: '10mb' }));
app.use(express.urlencoded({ extended: true, limit: '10mb' }));

// Request logging
app.use(requestLogger);

// Health check (before auth)
app.get('/', (req, res) => {
  res.json({
    name: 'PrivFed API',
    version: '1.0.0',
    description: 'Privacy-Preserving Federated Learning for Fraud Detection',
    docs: '/docs',
    health: '/api/health',
    timestamp: new Date().toISOString()
  });
});

// ============================================
// ROUTES
// ============================================

// Public routes
app.use('/api/auth', authRoutes);
app.use('/api', healthRoutes);

// Public/Protected routes
app.use('/api/status', statusRoutes);
app.use('/api/metrics', metricsRoutes);
app.use('/api/privacy', privacyRoutes); // ✅ Separate route file for correct mounting
app.use('/api/rounds', roundsRoutes);   // ✅ Separate route file for correct mounting
app.use('/api/fraud', fraudRoutes);
app.use('/api/banks', bankRoutes);
app.use('/api/analytics', analyticsRoutes);
app.use('/api/dataset', datasetRoutes);
app.use('/api/training', trainingRoutes); // ✅ Training results storage endpoint

// ============================================
// ERROR HANDLING
// ============================================

// 404 handler
app.use((req, res) => {
  res.status(404).json({
    error: 'Not Found',
    message: `Route ${req.method} ${req.path} not found`,
    timestamp: new Date().toISOString()
  });
});

// Global error handler (must be last)
app.use(errorHandler);

// ============================================
// SERVER STARTUP
// ============================================

const server = app.listen(PORT, () => {
  logger.info(`🚀 PrivFed API Server running on port ${PORT}`);
  logger.info(`📱 Environment: ${process.env.NODE_ENV || 'development'}`);
  logger.info(`🔗 API Base URL: http://localhost:${PORT}/api`);
});

// Graceful shutdown
process.on('SIGTERM', () => {
  logger.info('SIGTERM signal received: closing HTTP server');
  server.close(() => {
    logger.info('HTTP server closed');
    process.exit(0);
  });
});

process.on('SIGINT', () => {
  logger.info('SIGINT signal received: closing HTTP server');
  server.close(() => {
    logger.info('HTTP server closed');
    process.exit(0);
  });
});

export default app;
