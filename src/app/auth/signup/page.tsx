'use client'

import { useState } from 'react'
import { useRouter } from 'next/navigation'
import { stytchClient, oauthProviders } from '@/lib/auth/stytch-client'

export default function SignupPage() {
  const router = useRouter()
  const [email, setEmail] = useState('')
  const [name, setName] = useState('')
  const [organization, setOrganization] = useState('')
  const [loading, setLoading] = useState(false)
  const [error, setError] = useState('')
  const [message, setMessage] = useState('')

  // Handle Magic Link signup
  const handleSignup = async (e: React.FormEvent) => {
    e.preventDefault()
    setLoading(true)
    setError('')
    setMessage('')

    try {
      const response = await stytchClient.magicLinks.email.loginOrCreate({
        email,
        create_user_as_pending: false,
        signup_magic_link_url: `${window.location.origin}/auth/callback?name=${encodeURIComponent(name)}&org=${encodeURIComponent(organization)}`,
        login_magic_link_url: `${window.location.origin}/auth/callback`,
      })

      if (response.status_code === 200) {
        setMessage('Check your email to complete signup!')
      } else {
        throw new Error('Failed to send signup link')
      }
    } catch (err: any) {
      setError(err.message || 'Signup failed')
    } finally {
      setLoading(false)
    }
  }

  // Handle OAuth signup
  const handleOAuth = async (provider: string) => {
    setLoading(true)
    setError('')

    try {
      // Store name and organization in session storage for after OAuth
      sessionStorage.setItem('signup_name', name)
      sessionStorage.setItem('signup_organization', organization)

      await stytchClient.oauth.start({
        oauth_type: provider as any,
        signup_redirect_url: `${window.location.origin}/auth/callback`,
        login_redirect_url: `${window.location.origin}/auth/callback`,
        custom_scopes: {
          google: ['https://www.googleapis.com/auth/userinfo.profile'],
          github: ['user:email', 'read:org'],
        },
      })
    } catch (err: any) {
      setError(err.message || 'OAuth signup failed')
      setLoading(false)
    }
  }

  return (
    <div className="min-h-screen flex items-center justify-center bg-gradient-to-br from-green-50 to-teal-100 py-12 px-4 sm:px-6 lg:px-8">
      <div className="max-w-md w-full space-y-8">
        <div className="bg-white rounded-2xl shadow-xl p-8">
          {/* Header */}
          <div className="text-center mb-8">
            <h2 className="text-3xl font-bold text-gray-900">Create Account</h2>
            <p className="mt-2 text-sm text-gray-600">
              Join Toolbox Production today
            </p>
          </div>

          {/* Error/Success Messages */}
          {error && (
            <div className="mb-4 p-3 bg-red-50 border border-red-200 text-red-700 rounded-lg text-sm">
              {error}
            </div>
          )}
          {message && (
            <div className="mb-4 p-3 bg-green-50 border border-green-200 text-green-700 rounded-lg text-sm">
              {message}
            </div>
          )}

          {/* Signup Form */}
          <form onSubmit={handleSignup} className="space-y-4">
            <div>
              <label htmlFor="name" className="block text-sm font-medium text-gray-700">
                Full Name
              </label>
              <input
                id="name"
                name="name"
                type="text"
                autoComplete="name"
                required
                value={name}
                onChange={(e) => setName(e.target.value)}
                className="mt-1 appearance-none relative block w-full px-3 py-2 border border-gray-300 rounded-lg placeholder-gray-500 text-gray-900 focus:outline-none focus:ring-teal-500 focus:border-teal-500 focus:z-10 sm:text-sm"
                placeholder="John Doe"
              />
            </div>

            <div>
              <label htmlFor="email" className="block text-sm font-medium text-gray-700">
                Email Address
              </label>
              <input
                id="email"
                name="email"
                type="email"
                autoComplete="email"
                required
                value={email}
                onChange={(e) => setEmail(e.target.value)}
                className="mt-1 appearance-none relative block w-full px-3 py-2 border border-gray-300 rounded-lg placeholder-gray-500 text-gray-900 focus:outline-none focus:ring-teal-500 focus:border-teal-500 focus:z-10 sm:text-sm"
                placeholder="you@example.com"
              />
            </div>

            <div>
              <label htmlFor="organization" className="block text-sm font-medium text-gray-700">
                Organization (Optional)
              </label>
              <input
                id="organization"
                name="organization"
                type="text"
                autoComplete="organization"
                value={organization}
                onChange={(e) => setOrganization(e.target.value)}
                className="mt-1 appearance-none relative block w-full px-3 py-2 border border-gray-300 rounded-lg placeholder-gray-500 text-gray-900 focus:outline-none focus:ring-teal-500 focus:border-teal-500 focus:z-10 sm:text-sm"
                placeholder="Your Company"
              />
            </div>

            <button
              type="submit"
              disabled={loading}
              className="w-full flex justify-center py-2 px-4 border border-transparent rounded-lg shadow-sm text-sm font-medium text-white bg-teal-600 hover:bg-teal-700 focus:outline-none focus:ring-2 focus:ring-offset-2 focus:ring-teal-500 disabled:opacity-50 disabled:cursor-not-allowed transition-colors"
            >
              {loading ? 'Creating...' : 'Create Account'}
            </button>
          </form>

          {/* Divider */}
          <div className="relative my-6">
            <div className="absolute inset-0 flex items-center">
              <div className="w-full border-t border-gray-300" />
            </div>
            <div className="relative flex justify-center text-sm">
              <span className="px-2 bg-white text-gray-500">Or sign up with</span>
            </div>
          </div>

          {/* OAuth Providers */}
          <div className="grid grid-cols-2 gap-3">
            {oauthProviders.map((provider) => (
              <button
                key={provider.type}
                onClick={() => handleOAuth(provider.type)}
                disabled={loading}
                className="flex items-center justify-center px-4 py-2 border border-gray-300 rounded-lg shadow-sm text-sm font-medium text-gray-700 bg-white hover:bg-gray-50 focus:outline-none focus:ring-2 focus:ring-offset-2 focus:ring-teal-500 disabled:opacity-50 disabled:cursor-not-allowed transition-colors"
              >
                <span className="mr-2">{provider.icon}</span>
                <span className="hidden sm:inline">{provider.type.charAt(0).toUpperCase() + provider.type.slice(1)}</span>
              </button>
            ))}
          </div>

          {/* Terms */}
          <div className="mt-6 text-xs text-center text-gray-500">
            By signing up, you agree to our{' '}
            <a href="#" className="text-teal-600 hover:text-teal-500">
              Terms of Service
            </a>{' '}
            and{' '}
            <a href="#" className="text-teal-600 hover:text-teal-500">
              Privacy Policy
            </a>
          </div>

          {/* Sign In Link */}
          <div className="mt-6 text-center">
            <p className="text-sm text-gray-600">
              Already have an account?{' '}
              <a href="/auth/login" className="font-medium text-teal-600 hover:text-teal-500">
                Sign in
              </a>
            </p>
          </div>
        </div>
      </div>
    </div>
  )
}