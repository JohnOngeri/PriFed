/**
 * Email Utilities
 * Send emails using Nodemailer
 */

import nodemailer from 'nodemailer';
import { logger } from './logger.js';

// Create transporter (configure based on SMTP settings)
const createTransporter = () => {
  // If SMTP is not configured, log emails instead of sending (development mode)
  if (!process.env.SMTP_HOST) {
    logger.warn('SMTP not configured - emails will be logged instead of sent');
    return null; // Return null to indicate email logging mode
  }

  return nodemailer.createTransport({
    host: process.env.SMTP_HOST,
    port: parseInt(process.env.SMTP_PORT || '587'),
    secure: process.env.SMTP_SECURE === 'true',
    auth: {
      user: process.env.SMTP_USER,
      pass: process.env.SMTP_PASS
    }
  });
};

const transporter = createTransporter();
const fromEmail = process.env.EMAIL_FROM || 'noreply@privfed.com';
const fromName = process.env.EMAIL_FROM_NAME || 'PrivFed';

/**
 * Send email
 */
export const sendEmail = async (to, subject, html, text) => {
  try {
    const mailOptions = {
      from: `"${fromName}" <${fromEmail}>`,
      to,
      subject,
      text: text || html.replace(/<[^>]*>/g, ''), // Strip HTML for text version
      html
    };

    if (!transporter) {
      // Development mode - log email instead of sending
      logger.info('Email would be sent:', {
        to,
        subject,
        text: text || html.replace(/<[^>]*>/g, '')
      });
      return { success: true, message: 'Email logged (development mode)' };
    }

    const info = await transporter.sendMail(mailOptions);
    logger.info('Email sent successfully:', { to, subject, messageId: info.messageId });
    return { success: true, messageId: info.messageId };
  } catch (error) {
    logger.error('Error sending email:', error);
    throw new Error('Failed to send email');
  }
};

/**
 * Send password reset email
 */
export const sendPasswordResetEmail = async (email, resetToken, federationId) => {
  const appUrl = process.env.FRONTEND_URL || 'privfed://';
  const resetUrl = `${appUrl}reset-password?token=${resetToken}`;
  
  const subject = 'Reset Your PrivFed Password';
  const html = `
    <!DOCTYPE html>
    <html>
    <head>
      <style>
        body { font-family: Arial, sans-serif; line-height: 1.6; color: #333; }
        .container { max-width: 600px; margin: 0 auto; padding: 20px; }
        .button { display: inline-block; padding: 12px 24px; background-color: #64FFDA; color: #0A192F; text-decoration: none; border-radius: 4px; margin: 20px 0; font-weight: bold; }
        .footer { margin-top: 30px; padding-top: 20px; border-top: 1px solid #eee; font-size: 12px; color: #666; }
        .token-box { background-color: #f5f5f5; padding: 15px; border-radius: 4px; margin: 15px 0; font-family: monospace; word-break: break-all; }
        .info-box { background-color: #fff3cd; padding: 15px; border-radius: 4px; margin: 15px 0; border-left: 4px solid #ffc107; }
      </style>
    </head>
    <body>
      <div class="container">
        <h2>Password Reset Request</h2>
        <p>Hello,</p>
        <p>You have requested to reset your password for your PrivFed account (Federation ID: <strong>${federationId}</strong>).</p>
        
        <div class="info-box">
          <p><strong>Reset Token:</strong></p>
          <div class="token-box">${resetToken}</div>
          <p style="font-size: 12px; margin-top: 10px;">Copy this token and enter it in the PrivFed mobile app to reset your password.</p>
        </div>
        
        <p><strong>To reset your password:</strong></p>
        <ol>
          <li>Open the PrivFed mobile app</li>
          <li>Navigate to the Reset Password screen</li>
          <li>Enter the reset token above</li>
          <li>Enter your new password</li>
        </ol>
        
        <p><a href="${resetUrl}" class="button">Open PrivFed App</a></p>
        <p style="font-size: 12px; color: #666;">Or manually navigate to Reset Password in the app and enter the token.</p>
        
        <p><strong>⚠️ This token will expire in 1 hour.</strong></p>
        <p>If you did not request this password reset, please ignore this email or contact support if you have concerns.</p>
        
        <div class="footer">
          <p>This is an automated message from PrivFed. Please do not reply to this email.</p>
          <p>For security reasons, this link will expire in 1 hour.</p>
        </div>
      </div>
    </body>
    </html>
  `;

  return sendEmail(email, subject, html);
};

/**
 * Send welcome email with prominently displayed Federation ID
 */
export const sendWelcomeEmail = async (email, federationId) => {
  const appUrl = process.env.FRONTEND_URL || 'privfed://';
  const welcomeUrl = `${appUrl}login?federationId=${encodeURIComponent(federationId)}`;
  
  const subject = 'Welcome to PrivFed - Your Federation ID';
  const html = `
    <!DOCTYPE html>
    <html>
    <head>
      <style>
        body { font-family: Arial, sans-serif; line-height: 1.6; color: #333; }
        .container { max-width: 600px; margin: 0 auto; padding: 20px; }
        .button { display: inline-block; padding: 12px 24px; background-color: #00E5FF; color: #0A192F; text-decoration: none; border-radius: 4px; margin: 20px 0; font-weight: bold; }
        .footer { margin-top: 30px; padding-top: 20px; border-top: 1px solid #eee; font-size: 12px; color: #666; }
        .federation-id-box { background: linear-gradient(135deg, #00E5FF 0%, #64FFDA 100%); padding: 30px; border-radius: 8px; margin: 30px 0; text-align: center; border: 3px solid #00E5FF; box-shadow: 0 4px 15px rgba(0, 229, 255, 0.3); }
        .federation-id-label { font-size: 14px; color: #0A192F; font-weight: bold; text-transform: uppercase; letter-spacing: 1px; margin-bottom: 10px; }
        .federation-id-value { font-size: 48px; font-weight: bold; color: #0A192F; font-family: 'Courier New', monospace; letter-spacing: 4px; margin: 15px 0; }
        .warning-box { background-color: #fff3cd; padding: 20px; border-radius: 8px; margin: 20px 0; border-left: 4px solid #ffc107; }
        .warning-title { font-weight: bold; color: #856404; font-size: 16px; margin-bottom: 10px; }
        .warning-text { color: #856404; margin: 5px 0; }
        .info-section { background-color: #e7f3ff; padding: 20px; border-radius: 8px; margin: 20px 0; border-left: 4px solid #2196F3; }
        .info-title { font-weight: bold; color: #0d47a1; font-size: 16px; margin-bottom: 10px; }
        .info-text { color: #0d47a1; margin: 5px 0; }
      </style>
    </head>
    <body>
      <div class="container">
        <h2 style="color: #00E5FF;">Welcome to PrivFed!</h2>
        <p>Hello,</p>
        <p>Your account has been successfully created. Your Federation ID has been generated and is shown below.</p>
        
        <!-- Prominently Displayed Federation ID -->
        <div class="federation-id-box">
          <div class="federation-id-label">Your Federation ID</div>
          <div class="federation-id-value">${federationId}</div>
          <div style="font-size: 12px; color: #0A192F; margin-top: 10px;">Save this ID securely</div>
        </div>

        <!-- Critical Warning -->
        <div class="warning-box">
          <div class="warning-title">⚠️ IMPORTANT: Save Your Federation ID</div>
          <p class="warning-text"><strong>Your Federation ID cannot be recovered or regenerated.</strong></p>
          <p class="warning-text">This ID is required to:</p>
          <ul class="warning-text" style="margin: 10px 0; padding-left: 25px;">
            <li>Log in to the PrivFed mobile app</li>
            <li>Participate in federated learning rounds</li>
            <li>Access your federated learning data</li>
          </ul>
          <p class="warning-text"><strong>Please store this ID in a secure location.</strong></p>
        </div>

        <!-- Information Section -->
        <div class="info-section">
          <div class="info-title">📱 Next Steps</div>
          <p class="info-text">You can now log in to the PrivFed mobile app using:</p>
          <ul class="info-text" style="margin: 10px 0; padding-left: 25px;">
            <li><strong>Federation ID:</strong> ${federationId}</li>
            <li><strong>Your passcode:</strong> (the one you created during signup)</li>
          </ul>
        </div>

        <p style="margin-top: 30px;">
          <a href="${welcomeUrl}" class="button">Get Started in PrivFed</a>
        </p>

        <p>Thank you for joining the federated learning network!</p>
        
        <div class="footer">
          <p>This is an automated message from PrivFed. Please do not reply to this email.</p>
          <p style="margin-top: 10px; color: #999;">For security, we cannot regenerate your Federation ID. Keep it safe.</p>
        </div>
      </div>
    </body>
    </html>
  `;

  return sendEmail(email, subject, html);
};
