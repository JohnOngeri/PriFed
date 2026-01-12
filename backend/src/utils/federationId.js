/**
 * Federation ID Generator
 * Generates human-memorable 5-character Federation IDs
 * 
 * Format: 5 characters using A-Z and 2-9 (excluding 0, O, I, 1, L)
 * Provides ~1.2M unique combinations
 */

import crypto from 'crypto';
import { logger } from './logger.js';

// Character set: A-Z, 2-9 (excluding confusing characters: 0, O, I, 1, L)
// Total: 26 letters - 2 (O, I) = 24 letters + 8 digits (2-9) = 32 characters
const FEDERATION_ID_CHARS = 'ABCDEFGHJKMNPQRSTUVWXYZ23456789';
const FEDERATION_ID_LENGTH = 5;
const MAX_GENERATION_ATTEMPTS = 10; // Safe retry limit

/**
 * Generate a single Federation ID
 * @returns {string} 5-character Federation ID (uppercase)
 */
export const generateFederationId = () => {
  const randomBytes = crypto.randomBytes(FEDERATION_ID_LENGTH);
  let federationId = '';
  
  for (let i = 0; i < FEDERATION_ID_LENGTH; i++) {
    // Use modulo to map random byte to character set
    const charIndex = randomBytes[i] % FEDERATION_ID_CHARS.length;
    federationId += FEDERATION_ID_CHARS[charIndex];
  }
  
  return federationId;
};

/**
 * Generate a unique Federation ID with collision checking
 * @param {Function} checkExists - Async function that returns true if ID exists
 * @returns {Promise<string>} Unique Federation ID
 * @throws {Error} If unique ID cannot be generated after MAX_GENERATION_ATTEMPTS
 */
export const generateUniqueFederationId = async (checkExists) => {
  if (typeof checkExists !== 'function') {
    throw new Error('checkExists must be a function');
  }
  
  for (let attempt = 1; attempt <= MAX_GENERATION_ATTEMPTS; attempt++) {
    const candidateId = generateFederationId();
    const exists = await checkExists(candidateId);
    
    if (!exists) {
      logger.debug(`Generated Federation ID in ${attempt} attempt(s): ${candidateId}`);
      return candidateId;
    }
    
    logger.warn(`Federation ID collision detected (attempt ${attempt}/${MAX_GENERATION_ATTEMPTS}): ${candidateId}`);
  }
  
  throw new Error(`Failed to generate unique Federation ID after ${MAX_GENERATION_ATTEMPTS} attempts`);
};

/**
 * Normalize Federation ID (uppercase, trim)
 * @param {string} federationId - Input Federation ID
 * @returns {string} Normalized Federation ID
 */
export const normalizeFederationId = (federationId) => {
  if (!federationId || typeof federationId !== 'string') {
    return null;
  }
  return federationId.trim().toUpperCase();
};

/**
 * Validate Federation ID format
 * @param {string} federationId - Federation ID to validate
 * @returns {boolean} True if valid format
 */
export const isValidFederationIdFormat = (federationId) => {
  if (!federationId || typeof federationId !== 'string') {
    return false;
  }
  
  const normalized = normalizeFederationId(federationId);
  if (normalized.length !== FEDERATION_ID_LENGTH) {
    return false;
  }
  
  // Check all characters are in allowed set
  for (const char of normalized) {
    if (!FEDERATION_ID_CHARS.includes(char)) {
      return false;
    }
  }
  
  return true;
};
