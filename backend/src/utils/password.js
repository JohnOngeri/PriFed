/**
 * Password Utilities
 * Password hashing and validation
 */

import bcrypt from 'bcrypt';
import { logger } from './logger.js';

const BCRYPT_ROUNDS = parseInt(process.env.BCRYPT_ROUNDS || '12');

/**
 * Hash password
 */
export const hashPassword = async (password) => {
  try {
    const salt = await bcrypt.genSalt(BCRYPT_ROUNDS);
    return await bcrypt.hash(password, salt);
  } catch (error) {
    logger.error('Error hashing password:', error);
    throw new Error('Failed to hash password');
  }
};

/**
 * Compare password with hash
 */
export const comparePassword = async (password, hash) => {
  try {
    return await bcrypt.compare(password, hash);
  } catch (error) {
    logger.error('Error comparing password:', error);
    throw new Error('Failed to compare password');
  }
};

/**
 * Validate password strength
 */
export const validatePasswordStrength = (password) => {
  const minLength = 8;
  const hasUpperCase = /[A-Z]/.test(password);
  const hasLowerCase = /[a-z]/.test(password);
  const hasNumbers = /\d/.test(password);
  const hasSpecialChar = /[!@#$%^&*(),.?":{}|<>]/.test(password);

  const issues = [];
  
  if (password.length < minLength) {
    issues.push(`Password must be at least ${minLength} characters long`);
  }
  if (!hasUpperCase) {
    issues.push('Password must contain at least one uppercase letter');
  }
  if (!hasLowerCase) {
    issues.push('Password must contain at least one lowercase letter');
  }
  if (!hasNumbers) {
    issues.push('Password must contain at least one number');
  }

  return {
    isValid: issues.length === 0,
    issues
  };
};
