import { StytchUIClient } from '@stytch/nextjs/ui'
import { StytchHeadlessClient } from '@stytch/nextjs/headless'

/**
 * Stytch client configuration for authentication
 */

// Create UI client for pre-built components
export const stytchUIClient = new StytchUIClient(
  process.env.NEXT_PUBLIC_STYTCH_PUBLIC_TOKEN || ''
)

// Create headless client for custom implementations
export const stytchClient = new StytchHeadlessClient(
  process.env.NEXT_PUBLIC_STYTCH_PUBLIC_TOKEN || ''
)

// Stytch configuration
export const stytchConfig = {
  projectId: process.env.STYTCH_PROJECT_ID || '',
  secret: process.env.STYTCH_SECRET || '',
  publicToken: process.env.NEXT_PUBLIC_STYTCH_PUBLIC_TOKEN || '',
  projectDomain: process.env.STYTCH_PROJECT_DOMAIN || '',
  env: process.env.STYTCH_ENV || 'test',
}

// OAuth providers configuration
export const oauthProviders = [
  { type: 'google', display_name: 'Continue with Google', icon: '🔵' },
  { type: 'github', display_name: 'Continue with GitHub', icon: '⚫' },
  { type: 'microsoft', display_name: 'Continue with Microsoft', icon: '🟦' },
  { type: 'gitlab', display_name: 'Continue with GitLab', icon: '🟠' },
] as const

// Session configuration
export const sessionConfig = {
  sessionDurationMinutes: 480, // 8 hours
  sessionOptions: {
    max_age_seconds: 28800, // 8 hours
  },
}

// MFA configuration
export const mfaConfig = {
  enabled: true,
  enforcement: 'required' as const,
  allowedMethods: ['totp', 'sms'] as const,
  riskBased: true,
  trustDeviceDays: 30,
}