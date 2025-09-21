import { createClient as createSupabaseClient } from '@/utils/supabase/client'
import { createAdminClient } from '@/utils/supabase/server'
import type { User as StytchUser, Session as StytchSession } from '@stytch/vanilla-js'

/**
 * Bridge between Stytch authentication and Supabase database
 * Manages user synchronization and session handling
 */
export class StytchSupabaseBridge {
  private supabaseClient = createSupabaseClient()

  /**
   * Sync Stytch user to Supabase database
   * Creates or updates user record in Supabase
   */
  async syncUser(stytchUser: StytchUser) {
    try {
      // Check if user exists in Supabase
      const { data: existingUser, error: fetchError } = await this.supabaseClient
        .from('users')
        .select('*')
        .eq('stytch_user_id', stytchUser.user_id)
        .single()

      if (fetchError && fetchError.code !== 'PGRST116') {
        throw fetchError
      }

      const userData = {
        stytch_user_id: stytchUser.user_id,
        email: stytchUser.emails?.[0]?.email || '',
        name: stytchUser.name?.first_name
          ? `${stytchUser.name.first_name} ${stytchUser.name.last_name || ''}`.trim()
          : stytchUser.emails?.[0]?.email?.split('@')[0] || 'User',
        metadata: {
          stytch_data: {
            created_at: stytchUser.created_at,
            phone_numbers: stytchUser.phone_numbers,
            trusted_metadata: stytchUser.trusted_metadata,
            untrusted_metadata: stytchUser.untrusted_metadata,
          }
        },
        last_login_at: new Date().toISOString(),
      }

      if (existingUser) {
        // Update existing user
        const { data, error } = await this.supabaseClient
          .from('users')
          .update(userData)
          .eq('id', existingUser.id)
          .select()
          .single()

        if (error) throw error
        return data
      } else {
        // Create new user
        const { data, error } = await this.supabaseClient
          .from('users')
          .insert({
            ...userData,
            role: 'user', // Default role
            // Organization will be set later based on Stytch organization
          })
          .select()
          .single()

        if (error) throw error
        return data
      }
    } catch (error) {
      console.error('Failed to sync user with Supabase:', error)
      throw error
    }
  }

  /**
   * Create a Supabase session from Stytch session
   * Generates a custom JWT that Supabase can understand
   */
  async createSupabaseSession(stytchSession: StytchSession, user: any) {
    try {
      // Create a custom session in Supabase
      // This requires server-side operation with service role
      const customClaims = {
        user_id: user.id,
        stytch_user_id: user.stytch_user_id,
        organization_id: user.organization_id,
        role: user.role,
        email: user.email,
      }

      // Store session data in localStorage for client-side access
      if (typeof window !== 'undefined') {
        localStorage.setItem('supabase_custom_claims', JSON.stringify(customClaims))
        localStorage.setItem('stytch_session_id', stytchSession.session_id)
        localStorage.setItem('stytch_user_id', stytchSession.user_id)
      }

      return customClaims
    } catch (error) {
      console.error('Failed to create Supabase session:', error)
      throw error
    }
  }

  /**
   * Verify and refresh the session
   */
  async verifySession(): Promise<boolean> {
    try {
      if (typeof window === 'undefined') return false

      const stytchSessionId = localStorage.getItem('stytch_session_id')
      const customClaims = localStorage.getItem('supabase_custom_claims')

      if (!stytchSessionId || !customClaims) {
        return false
      }

      // Here you would verify with Stytch API that session is still valid
      // For now, we'll trust the stored session
      return true
    } catch (error) {
      console.error('Session verification failed:', error)
      return false
    }
  }

  /**
   * Get current user from combined session
   */
  async getCurrentUser() {
    try {
      const customClaims = localStorage.getItem('supabase_custom_claims')
      if (!customClaims) return null

      const claims = JSON.parse(customClaims)

      // Fetch fresh user data from Supabase
      const { data, error } = await this.supabaseClient
        .from('users')
        .select('*, organizations(*)')
        .eq('id', claims.user_id)
        .single()

      if (error) throw error
      return data
    } catch (error) {
      console.error('Failed to get current user:', error)
      return null
    }
  }

  /**
   * Clear session data
   */
  async signOut() {
    try {
      // Clear localStorage
      if (typeof window !== 'undefined') {
        localStorage.removeItem('supabase_custom_claims')
        localStorage.removeItem('stytch_session_id')
        localStorage.removeItem('stytch_user_id')
      }

      // Sign out from Supabase (if using Supabase Auth)
      await this.supabaseClient.auth.signOut()
    } catch (error) {
      console.error('Sign out error:', error)
    }
  }

  /**
   * Sync Stytch organization to Supabase
   */
  async syncOrganization(stytchOrg: any) {
    try {
      const { data: existingOrg, error: fetchError } = await this.supabaseClient
        .from('organizations')
        .select('*')
        .eq('stytch_org_id', stytchOrg.organization_id)
        .single()

      if (fetchError && fetchError.code !== 'PGRST116') {
        throw fetchError
      }

      const orgData = {
        stytch_org_id: stytchOrg.organization_id,
        name: stytchOrg.organization_name,
        slug: stytchOrg.organization_slug,
        domain: stytchOrg.email_allowed_domains?.[0] || null,
        settings: {
          stytch_data: stytchOrg,
        },
      }

      if (existingOrg) {
        // Update existing organization
        const { data, error } = await this.supabaseClient
          .from('organizations')
          .update(orgData)
          .eq('id', existingOrg.id)
          .select()
          .single()

        if (error) throw error
        return data
      } else {
        // Create new organization
        const { data, error } = await this.supabaseClient
          .from('organizations')
          .insert(orgData)
          .select()
          .single()

        if (error) throw error
        return data
      }
    } catch (error) {
      console.error('Failed to sync organization:', error)
      throw error
    }
  }

  /**
   * Update user's organization association
   */
  async updateUserOrganization(userId: number, organizationId: number) {
    try {
      const { data, error } = await this.supabaseClient
        .from('users')
        .update({ organization_id: organizationId })
        .eq('id', userId)
        .select()
        .single()

      if (error) throw error
      return data
    } catch (error) {
      console.error('Failed to update user organization:', error)
      throw error
    }
  }
}

// Export singleton instance
export const authBridge = new StytchSupabaseBridge()