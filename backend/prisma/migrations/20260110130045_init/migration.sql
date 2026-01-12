-- CreateEnum
CREATE TYPE "UserRole" AS ENUM ('PUBLIC', 'ADMIN', 'BANK_ADMIN', 'BANK_USER');

-- CreateEnum
CREATE TYPE "BankApplicationStatus" AS ENUM ('PENDING', 'APPROVED', 'REJECTED');

-- CreateEnum
CREATE TYPE "VoteType" AS ENUM ('APPROVE', 'REJECT');

-- CreateEnum
CREATE TYPE "TrainingStatus" AS ENUM ('NOT_STARTED', 'RUNNING', 'COMPLETED', 'FAILED', 'PAUSED');

-- CreateEnum
CREATE TYPE "RiskLevel" AS ENUM ('LOW', 'MEDIUM', 'HIGH');

-- CreateEnum
CREATE TYPE "NotificationType" AS ENUM ('SYSTEM', 'BANK_APPLICATION', 'TRAINING_UPDATE', 'FRAUD_ALERT', 'SECURITY');

-- CreateTable
CREATE TABLE "users" (
    "id" TEXT NOT NULL,
    "email" TEXT NOT NULL,
    "federationId" TEXT NOT NULL,
    "passwordHash" TEXT NOT NULL,
    "role" "UserRole" NOT NULL DEFAULT 'PUBLIC',
    "bankId" TEXT,
    "isActive" BOOLEAN NOT NULL DEFAULT true,
    "lastLoginAt" TIMESTAMP(3),
    "createdAt" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "updatedAt" TIMESTAMP(3) NOT NULL,

    CONSTRAINT "users_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "refresh_tokens" (
    "id" TEXT NOT NULL,
    "token" TEXT NOT NULL,
    "userId" TEXT NOT NULL,
    "deviceId" TEXT,
    "ipAddress" TEXT,
    "userAgent" TEXT,
    "expiresAt" TIMESTAMP(3) NOT NULL,
    "revokedAt" TIMESTAMP(3),
    "createdAt" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT "refresh_tokens_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "sessions" (
    "id" TEXT NOT NULL,
    "userId" TEXT NOT NULL,
    "token" TEXT NOT NULL,
    "deviceId" TEXT,
    "ipAddress" TEXT,
    "userAgent" TEXT,
    "expiresAt" TIMESTAMP(3) NOT NULL,
    "createdAt" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT "sessions_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "password_reset_tokens" (
    "id" TEXT NOT NULL,
    "userId" TEXT NOT NULL,
    "token" TEXT NOT NULL,
    "expiresAt" TIMESTAMP(3) NOT NULL,
    "usedAt" TIMESTAMP(3),
    "createdAt" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT "password_reset_tokens_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "banks" (
    "id" TEXT NOT NULL,
    "bankId" TEXT NOT NULL,
    "name" TEXT NOT NULL,
    "subtitle" TEXT,
    "color" TEXT NOT NULL DEFAULT 'blue',
    "icon" TEXT NOT NULL DEFAULT 'building_modern',
    "isActive" BOOLEAN NOT NULL DEFAULT true,
    "joinedAt" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "createdAt" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "updatedAt" TIMESTAMP(3) NOT NULL,

    CONSTRAINT "banks_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "bank_applications" (
    "id" TEXT NOT NULL,
    "bankId" TEXT NOT NULL,
    "bankName" TEXT NOT NULL,
    "licenseNumber" TEXT NOT NULL,
    "contactEmail" TEXT NOT NULL,
    "contactPhone" TEXT NOT NULL,
    "address" TEXT NOT NULL,
    "status" "BankApplicationStatus" NOT NULL DEFAULT 'PENDING',
    "submittedAt" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "reviewedAt" TIMESTAMP(3),
    "approvedAt" TIMESTAMP(3),
    "rejectedAt" TIMESTAMP(3),
    "notes" TEXT,

    CONSTRAINT "bank_applications_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "bank_application_votes" (
    "id" TEXT NOT NULL,
    "applicationId" TEXT NOT NULL,
    "bankId" TEXT NOT NULL,
    "vote" "VoteType" NOT NULL,
    "createdAt" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT "bank_application_votes_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "training_rounds" (
    "id" TEXT NOT NULL,
    "roundNumber" INTEGER NOT NULL,
    "status" "TrainingStatus" NOT NULL DEFAULT 'RUNNING',
    "globalMetricsId" TEXT NOT NULL,
    "privacyMetricsId" TEXT,
    "duration" DOUBLE PRECISION,
    "startedAt" TIMESTAMP(3) NOT NULL,
    "completedAt" TIMESTAMP(3),
    "createdAt" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT "training_rounds_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "bank_training_rounds" (
    "id" TEXT NOT NULL,
    "roundId" TEXT NOT NULL,
    "bankId" TEXT NOT NULL,
    "metricsId" TEXT NOT NULL,
    "samples" INTEGER NOT NULL,
    "fraudRate" DOUBLE PRECISION NOT NULL,
    "createdAt" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT "bank_training_rounds_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "classification_metrics" (
    "id" TEXT NOT NULL,
    "auc" DOUBLE PRECISION NOT NULL,
    "accuracy" DOUBLE PRECISION NOT NULL,
    "precision" DOUBLE PRECISION NOT NULL,
    "recall" DOUBLE PRECISION NOT NULL,
    "f1" DOUBLE PRECISION NOT NULL,
    "loss" DOUBLE PRECISION DEFAULT 0.0,
    "specificity" DOUBLE PRECISION DEFAULT 0.0,
    "timestamp" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT "classification_metrics_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "bank_metrics" (
    "id" TEXT NOT NULL,
    "bankId" TEXT NOT NULL,
    "metricsId" TEXT NOT NULL,
    "roundNumber" INTEGER,
    "samples" INTEGER,
    "fraudRate" DOUBLE PRECISION,
    "timestamp" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT "bank_metrics_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "privacy_metrics" (
    "id" TEXT NOT NULL,
    "currentEpsilon" DOUBLE PRECISION NOT NULL,
    "targetEpsilon" DOUBLE PRECISION NOT NULL,
    "delta" DOUBLE PRECISION NOT NULL,
    "noiseMultiplier" DOUBLE PRECISION NOT NULL,
    "privacyStrength" TEXT NOT NULL,
    "budgetUsedPercentage" DOUBLE PRECISION NOT NULL,
    "timestamp" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT "privacy_metrics_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "fraud_transactions" (
    "id" TEXT NOT NULL,
    "transactionId" TEXT NOT NULL,
    "bankId" TEXT,
    "amount" DOUBLE PRECISION NOT NULL,
    "fraudProbability" DOUBLE PRECISION NOT NULL,
    "riskLevel" "RiskLevel" NOT NULL,
    "features" JSONB NOT NULL,
    "riskFactors" TEXT[],
    "bankPredictions" JSONB,
    "timestamp" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "createdAt" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT "fraud_transactions_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "notifications" (
    "id" TEXT NOT NULL,
    "userId" TEXT,
    "type" "NotificationType" NOT NULL,
    "title" TEXT NOT NULL,
    "message" TEXT NOT NULL,
    "isRead" BOOLEAN NOT NULL DEFAULT false,
    "metadata" JSONB,
    "createdAt" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT "notifications_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "system_config" (
    "id" TEXT NOT NULL,
    "key" TEXT NOT NULL,
    "value" JSONB NOT NULL,
    "updatedAt" TIMESTAMP(3) NOT NULL,
    "updatedBy" TEXT,

    CONSTRAINT "system_config_pkey" PRIMARY KEY ("id")
);

-- CreateIndex
CREATE UNIQUE INDEX "users_email_key" ON "users"("email");

-- CreateIndex
CREATE UNIQUE INDEX "users_federationId_key" ON "users"("federationId");

-- CreateIndex
CREATE INDEX "users_federationId_idx" ON "users"("federationId");

-- CreateIndex
CREATE INDEX "users_email_idx" ON "users"("email");

-- CreateIndex
CREATE INDEX "users_bankId_idx" ON "users"("bankId");

-- CreateIndex
CREATE UNIQUE INDEX "refresh_tokens_token_key" ON "refresh_tokens"("token");

-- CreateIndex
CREATE INDEX "refresh_tokens_userId_idx" ON "refresh_tokens"("userId");

-- CreateIndex
CREATE INDEX "refresh_tokens_token_idx" ON "refresh_tokens"("token");

-- CreateIndex
CREATE INDEX "refresh_tokens_expiresAt_idx" ON "refresh_tokens"("expiresAt");

-- CreateIndex
CREATE UNIQUE INDEX "sessions_token_key" ON "sessions"("token");

-- CreateIndex
CREATE INDEX "sessions_userId_idx" ON "sessions"("userId");

-- CreateIndex
CREATE INDEX "sessions_token_idx" ON "sessions"("token");

-- CreateIndex
CREATE INDEX "sessions_expiresAt_idx" ON "sessions"("expiresAt");

-- CreateIndex
CREATE UNIQUE INDEX "password_reset_tokens_token_key" ON "password_reset_tokens"("token");

-- CreateIndex
CREATE INDEX "password_reset_tokens_userId_idx" ON "password_reset_tokens"("userId");

-- CreateIndex
CREATE INDEX "password_reset_tokens_token_idx" ON "password_reset_tokens"("token");

-- CreateIndex
CREATE INDEX "password_reset_tokens_expiresAt_idx" ON "password_reset_tokens"("expiresAt");

-- CreateIndex
CREATE UNIQUE INDEX "banks_bankId_key" ON "banks"("bankId");

-- CreateIndex
CREATE INDEX "banks_bankId_idx" ON "banks"("bankId");

-- CreateIndex
CREATE INDEX "banks_isActive_idx" ON "banks"("isActive");

-- CreateIndex
CREATE UNIQUE INDEX "bank_applications_bankId_key" ON "bank_applications"("bankId");

-- CreateIndex
CREATE INDEX "bank_applications_status_idx" ON "bank_applications"("status");

-- CreateIndex
CREATE INDEX "bank_applications_submittedAt_idx" ON "bank_applications"("submittedAt");

-- CreateIndex
CREATE INDEX "bank_application_votes_applicationId_idx" ON "bank_application_votes"("applicationId");

-- CreateIndex
CREATE INDEX "bank_application_votes_bankId_idx" ON "bank_application_votes"("bankId");

-- CreateIndex
CREATE UNIQUE INDEX "bank_application_votes_applicationId_bankId_key" ON "bank_application_votes"("applicationId", "bankId");

-- CreateIndex
CREATE UNIQUE INDEX "training_rounds_globalMetricsId_key" ON "training_rounds"("globalMetricsId");

-- CreateIndex
CREATE UNIQUE INDEX "training_rounds_privacyMetricsId_key" ON "training_rounds"("privacyMetricsId");

-- CreateIndex
CREATE INDEX "training_rounds_roundNumber_idx" ON "training_rounds"("roundNumber");

-- CreateIndex
CREATE INDEX "training_rounds_status_idx" ON "training_rounds"("status");

-- CreateIndex
CREATE INDEX "training_rounds_startedAt_idx" ON "training_rounds"("startedAt");

-- CreateIndex
CREATE UNIQUE INDEX "training_rounds_roundNumber_key" ON "training_rounds"("roundNumber");

-- CreateIndex
CREATE UNIQUE INDEX "bank_training_rounds_metricsId_key" ON "bank_training_rounds"("metricsId");

-- CreateIndex
CREATE INDEX "bank_training_rounds_roundId_idx" ON "bank_training_rounds"("roundId");

-- CreateIndex
CREATE INDEX "bank_training_rounds_bankId_idx" ON "bank_training_rounds"("bankId");

-- CreateIndex
CREATE UNIQUE INDEX "bank_training_rounds_roundId_bankId_key" ON "bank_training_rounds"("roundId", "bankId");

-- CreateIndex
CREATE INDEX "bank_metrics_bankId_idx" ON "bank_metrics"("bankId");

-- CreateIndex
CREATE INDEX "bank_metrics_roundNumber_idx" ON "bank_metrics"("roundNumber");

-- CreateIndex
CREATE INDEX "bank_metrics_timestamp_idx" ON "bank_metrics"("timestamp");

-- CreateIndex
CREATE UNIQUE INDEX "fraud_transactions_transactionId_key" ON "fraud_transactions"("transactionId");

-- CreateIndex
CREATE INDEX "fraud_transactions_bankId_idx" ON "fraud_transactions"("bankId");

-- CreateIndex
CREATE INDEX "fraud_transactions_riskLevel_idx" ON "fraud_transactions"("riskLevel");

-- CreateIndex
CREATE INDEX "fraud_transactions_timestamp_idx" ON "fraud_transactions"("timestamp");

-- CreateIndex
CREATE INDEX "fraud_transactions_fraudProbability_idx" ON "fraud_transactions"("fraudProbability");

-- CreateIndex
CREATE INDEX "notifications_userId_idx" ON "notifications"("userId");

-- CreateIndex
CREATE INDEX "notifications_isRead_idx" ON "notifications"("isRead");

-- CreateIndex
CREATE INDEX "notifications_createdAt_idx" ON "notifications"("createdAt");

-- CreateIndex
CREATE UNIQUE INDEX "system_config_key_key" ON "system_config"("key");

-- AddForeignKey
ALTER TABLE "users" ADD CONSTRAINT "users_bankId_fkey" FOREIGN KEY ("bankId") REFERENCES "banks"("id") ON DELETE SET NULL ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "refresh_tokens" ADD CONSTRAINT "refresh_tokens_userId_fkey" FOREIGN KEY ("userId") REFERENCES "users"("id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "sessions" ADD CONSTRAINT "sessions_userId_fkey" FOREIGN KEY ("userId") REFERENCES "users"("id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "bank_applications" ADD CONSTRAINT "bank_applications_bankId_fkey" FOREIGN KEY ("bankId") REFERENCES "banks"("id") ON DELETE RESTRICT ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "bank_application_votes" ADD CONSTRAINT "bank_application_votes_applicationId_fkey" FOREIGN KEY ("applicationId") REFERENCES "bank_applications"("id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "bank_application_votes" ADD CONSTRAINT "bank_application_votes_bankId_fkey" FOREIGN KEY ("bankId") REFERENCES "banks"("id") ON DELETE RESTRICT ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "training_rounds" ADD CONSTRAINT "training_rounds_globalMetricsId_fkey" FOREIGN KEY ("globalMetricsId") REFERENCES "classification_metrics"("id") ON DELETE RESTRICT ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "training_rounds" ADD CONSTRAINT "training_rounds_privacyMetricsId_fkey" FOREIGN KEY ("privacyMetricsId") REFERENCES "privacy_metrics"("id") ON DELETE SET NULL ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "bank_training_rounds" ADD CONSTRAINT "bank_training_rounds_roundId_fkey" FOREIGN KEY ("roundId") REFERENCES "training_rounds"("id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "bank_training_rounds" ADD CONSTRAINT "bank_training_rounds_bankId_fkey" FOREIGN KEY ("bankId") REFERENCES "banks"("id") ON DELETE RESTRICT ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "bank_training_rounds" ADD CONSTRAINT "bank_training_rounds_metricsId_fkey" FOREIGN KEY ("metricsId") REFERENCES "classification_metrics"("id") ON DELETE RESTRICT ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "bank_metrics" ADD CONSTRAINT "bank_metrics_bankId_fkey" FOREIGN KEY ("bankId") REFERENCES "banks"("id") ON DELETE RESTRICT ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "bank_metrics" ADD CONSTRAINT "bank_metrics_metricsId_fkey" FOREIGN KEY ("metricsId") REFERENCES "classification_metrics"("id") ON DELETE RESTRICT ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "fraud_transactions" ADD CONSTRAINT "fraud_transactions_bankId_fkey" FOREIGN KEY ("bankId") REFERENCES "banks"("id") ON DELETE SET NULL ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "notifications" ADD CONSTRAINT "notifications_userId_fkey" FOREIGN KEY ("userId") REFERENCES "users"("id") ON DELETE CASCADE ON UPDATE CASCADE;
