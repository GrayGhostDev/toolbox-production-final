'use client'

import { useEffect, useState } from 'react'
import { useRouter, useSearchParams } from 'next/navigation'
import { stytchClient } from '@/lib/auth/stytch-client'
import { authBridge } from '@/lib/auth/stytch-supabase-bridge'

export default function AuthCallback() {
  const router = useRouter()
  const searchParams = useSearchParams()
  const [status, setStatus] = useState('Authenticating...')
  const [error, setError] = useState('')

  useEffect(() => {
    const handleCallback = async () => {
      try {
        // Get token from URL
        const token = searchParams.get('token')
        const stytch_token_type = searchParams.get('stytch_token_type')
        const name = searchParams.get('name')
        const org = searchParams.get('org')

        if (token && stytch_token_type === 'magic_links') {
          // Handle Magic Link authentication
          setStatus('Verifying magic link...')

          const response = await stytchClient.magicLinks.authenticate({
            token,
            session_duration_minutes: 480,
          })

          if (response.status_code === 200) {
            // Sync with Supabase
            setStatus('Setting up your account...')

            const user = await authBridge.syncUser(response.user)

            // If organization was provided, sync that too
            if (org) {
              // In a real app, you would create or join an organization here
              console.log('Organization requested:', org)
            }

            // Update user name if provided
            if (name && user) {
              // Update user profile with name
              console.log('Setting user name:', name)
            }

            // Create Supabase session
            await authBridge.createSupabaseSession(response.session, user)

            setStatus('Success! Redirecting to dashboard...')
            setTimeout(() => {
              router.push('/dashboard')
            }, 1000)
          } else {
            throw new Error('Authentication failed')
          }
        } else if (token && stytch_token_type === 'oauth') {
          // Handle OAuth authentication
          setStatus('Completing OAuth login...')

          const response = await stytchClient.oauth.authenticate({
            token,
            session_duration_minutes: 480,
          })

          if (response.status_code === 200) {
            // Sync with Supabase
            setStatus('Setting up your account...')

            const user = await authBridge.syncUser(response.user)

            // Check for stored signup data
            const signupName = sessionStorage.getItem('signup_name')
            const signupOrg = sessionStorage.getItem('signup_organization')

            if (signupName || signupOrg) {
              console.log('Signup data:', { name: signupName, organization: signupOrg })
              // Clear stored data
              sessionStorage.removeItem('signup_name')
              sessionStorage.removeItem('signup_organization')
            }

            // Create Supabase session
            await authBridge.createSupabaseSession(response.session, user)

            setStatus('Success! Redirecting to dashboard...')
            setTimeout(() => {
              router.push('/dashboard')
            }, 1000)
          } else {
            throw new Error('OAuth authentication failed')
          }
        } else {
          // No token found, might be returning from OAuth provider
          setStatus('Completing authentication...')

          // Check if we have a session already
          const session = await stytchClient.sessions.get()

          if (session) {
            // Get user data
            const user = await stytchClient.users.get(session.user_id)

            if (user) {
              // Sync with Supabase
              const supabaseUser = await authBridge.syncUser(user)
              await authBridge.createSupabaseSession(session, supabaseUser)

              setStatus('Success! Redirecting to dashboard...')
              setTimeout(() => {
                router.push('/dashboard')
              }, 1000)
            }
          } else {
            throw new Error('No authentication token found')
          }
        }
      } catch (err: any) {
        console.error('Authentication error:', err)
        setError(err.message || 'Authentication failed')
        setStatus('Authentication failed')

        // Redirect to login after error
        setTimeout(() => {
          router.push('/auth/login')
        }, 3000)
      }
    }

    handleCallback()
  }, [searchParams, router])

  return (
    <div className="min-h-screen flex items-center justify-center bg-gradient-to-br from-indigo-50 to-purple-100">
      <div className="bg-white rounded-2xl shadow-xl p-8 max-w-md w-full">
        <div className="text-center">
          {!error ? (
            <>
              <div className="mb-4">
                <div className="inline-flex items-center justify-center w-16 h-16 rounded-full bg-indigo-100">
                  <svg
                    className="w-8 h-8 text-indigo-600 animate-spin"
                    xmlns="http://www.w3.org/2000/svg"
                    fill="none"
                    viewBox="0 0 24 24"
                  >
                    <circle
                      className="opacity-25"
                      cx="12"
                      cy="12"
                      r="10"
                      stroke="currentColor"
                      strokeWidth="4"
                    />
                    <path
                      className="opacity-75"
                      fill="currentColor"
                      d="M4 12a8 8 0 018-8V0C5.373 0 0 5.373 0 12h4zm2 5.291A7.962 7.962 0 014 12H0c0 3.042 1.135 5.824 3 7.938l3-2.647z"
                    />
                  </svg>
                </div>
              </div>
              <h2 className="text-2xl font-bold text-gray-900 mb-2">
                {status}
              </h2>
              <p className="text-gray-600">
                Please wait while we complete your authentication...
              </p>
            </>
          ) : (
            <>
              <div className="mb-4">
                <div className="inline-flex items-center justify-center w-16 h-16 rounded-full bg-red-100">
                  <svg
                    className="w-8 h-8 text-red-600"
                    fill="none"
                    stroke="currentColor"
                    viewBox="0 0 24 24"
                  >
                    <path
                      strokeLinecap="round"
                      strokeLinejoin="round"
                      strokeWidth="2"
                      d="M12 8v4m0 4h.01M21 12a9 9 0 11-18 0 9 9 0 0118 0z"
                    />
                  </svg>
                </div>
              </div>
              <h2 className="text-2xl font-bold text-gray-900 mb-2">
                Authentication Failed
              </h2>
              <p className="text-red-600 mb-4">{error}</p>
              <p className="text-gray-600">
                Redirecting you back to login...
              </p>
            </>
          )}
        </div>
      </div>
    </div>
  )
}