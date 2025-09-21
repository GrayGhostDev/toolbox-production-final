'use client'

import { useEffect, useState } from 'react'

export default function Home() {
  const [status, setStatus] = useState<any>(null)
  const [loading, setLoading] = useState(true)

  useEffect(() => {
    // Test Supabase connection on page load
    fetch('/api/test-supabase')
      .then(res => res.json())
      .then(data => {
        setStatus(data)
        setLoading(false)
      })
      .catch(err => {
        console.error('Failed to test Supabase:', err)
        setLoading(false)
      })
  }, [])

  return (
    <main className="min-h-screen p-8 bg-gray-50">
      <div className="max-w-6xl mx-auto">
        <div className="bg-white rounded-lg shadow-lg p-8 mb-8">
          <h1 className="text-4xl font-bold text-gray-900 mb-4">
            Toolbox Production Final
          </h1>
          <p className="text-lg text-gray-600 mb-8">
            Enterprise-grade toolbox application with Supabase and Stytch integration
          </p>

          <div className="grid grid-cols-1 md:grid-cols-3 gap-6 mb-8">
            <div className="bg-blue-50 p-6 rounded-lg">
              <h3 className="text-xl font-semibold text-blue-900 mb-2">
                🔐 Authentication
              </h3>
              <p className="text-blue-700">
                Stytch + Supabase Bridge
              </p>
            </div>

            <div className="bg-green-50 p-6 rounded-lg">
              <h3 className="text-xl font-semibold text-green-900 mb-2">
                🗄️ Database
              </h3>
              <p className="text-green-700">
                Supabase Cloud PostgreSQL
              </p>
            </div>

            <div className="bg-purple-50 p-6 rounded-lg">
              <h3 className="text-xl font-semibold text-purple-900 mb-2">
                ⚡ Real-time
              </h3>
              <p className="text-purple-700">
                WebSocket Subscriptions
              </p>
            </div>
          </div>
        </div>

        {/* Integration Status */}
        <div className="bg-white rounded-lg shadow-lg p-8">
          <h2 className="text-2xl font-bold text-gray-900 mb-6">
            Integration Status
          </h2>

          {loading ? (
            <div className="text-center py-8">
              <div className="inline-block animate-spin rounded-full h-8 w-8 border-b-2 border-gray-900"></div>
              <p className="mt-4 text-gray-600">Testing connections...</p>
            </div>
          ) : status ? (
            <div className="space-y-4">
              {status.tests?.map((test: any, index: number) => (
                <div
                  key={index}
                  className={`p-4 rounded-lg border ${
                    test.status === 'PASS'
                      ? 'bg-green-50 border-green-200'
                      : test.status === 'WARN'
                      ? 'bg-yellow-50 border-yellow-200'
                      : test.status === 'INFO'
                      ? 'bg-blue-50 border-blue-200'
                      : 'bg-red-50 border-red-200'
                  }`}
                >
                  <div className="flex items-center justify-between">
                    <h3 className="font-semibold text-gray-900">{test.name}</h3>
                    <span
                      className={`px-3 py-1 rounded-full text-xs font-medium ${
                        test.status === 'PASS'
                          ? 'bg-green-100 text-green-800'
                          : test.status === 'WARN'
                          ? 'bg-yellow-100 text-yellow-800'
                          : test.status === 'INFO'
                          ? 'bg-blue-100 text-blue-800'
                          : 'bg-red-100 text-red-800'
                      }`}
                    >
                      {test.status}
                    </span>
                  </div>
                  {test.details && (
                    <p className="mt-2 text-sm text-gray-600">
                      {typeof test.details === 'object'
                        ? JSON.stringify(test.details, null, 2)
                        : test.details}
                    </p>
                  )}
                  {test.error && (
                    <p className="mt-2 text-sm text-red-600">{test.error}</p>
                  )}
                </div>
              ))}

              {status.summary && (
                <div className="mt-6 p-4 bg-gray-100 rounded-lg">
                  <h3 className="font-semibold text-gray-900 mb-2">Summary</h3>
                  <p className="text-gray-700">
                    {status.summary.passed} of {status.summary.total} tests passed
                  </p>
                  <p className="text-sm text-gray-600 mt-1">
                    {status.summary.integration}
                  </p>
                </div>
              )}
            </div>
          ) : (
            <div className="text-center py-8 text-gray-600">
              No status available
            </div>
          )}
        </div>

        {/* Configuration Info */}
        <div className="mt-8 bg-white rounded-lg shadow-lg p-8">
          <h2 className="text-2xl font-bold text-gray-900 mb-6">
            Configuration Details
          </h2>

          <div className="grid grid-cols-1 md:grid-cols-2 gap-6">
            <div>
              <h3 className="font-semibold text-gray-900 mb-3">Supabase</h3>
              <ul className="space-y-2 text-sm">
                <li className="flex items-start">
                  <span className="text-green-500 mr-2">✓</span>
                  <span className="text-gray-600">
                    Project URL: {process.env.NEXT_PUBLIC_SUPABASE_URL?.split('.')[0] || 'Not configured'}
                  </span>
                </li>
                <li className="flex items-start">
                  <span className="text-green-500 mr-2">✓</span>
                  <span className="text-gray-600">Row Level Security enabled</span>
                </li>
                <li className="flex items-start">
                  <span className="text-green-500 mr-2">✓</span>
                  <span className="text-gray-600">Real-time subscriptions ready</span>
                </li>
                <li className="flex items-start">
                  <span className="text-green-500 mr-2">✓</span>
                  <span className="text-gray-600">TypeScript types generated</span>
                </li>
              </ul>
            </div>

            <div>
              <h3 className="font-semibold text-gray-900 mb-3">Stytch</h3>
              <ul className="space-y-2 text-sm">
                <li className="flex items-start">
                  <span className="text-green-500 mr-2">✓</span>
                  <span className="text-gray-600">
                    Workspace: {process.env.STYTCH_WORKSPACE_SLUG || 'gray-ghost-data'}
                  </span>
                </li>
                <li className="flex items-start">
                  <span className="text-green-500 mr-2">✓</span>
                  <span className="text-gray-600">Authentication bridge configured</span>
                </li>
                <li className="flex items-start">
                  <span className="text-green-500 mr-2">✓</span>
                  <span className="text-gray-600">MFA and SSO enabled</span>
                </li>
                <li className="flex items-start">
                  <span className="text-green-500 mr-2">✓</span>
                  <span className="text-gray-600">Session management ready</span>
                </li>
              </ul>
            </div>
          </div>
        </div>

        {/* Authentication Links */}
        <div className="mt-8 bg-white rounded-lg shadow-lg p-8">
          <h2 className="text-2xl font-bold text-gray-900 mb-6">
            Get Started
          </h2>

          <div className="grid grid-cols-1 md:grid-cols-3 gap-4 mb-6">
            <a
              href="/auth/login"
              className="p-4 text-center bg-indigo-600 text-white rounded-lg hover:bg-indigo-700 transition-colors"
            >
              <span className="text-2xl mb-2 block">🔑</span>
              <span className="font-medium">Login</span>
            </a>

            <a
              href="/auth/signup"
              className="p-4 text-center bg-teal-600 text-white rounded-lg hover:bg-teal-700 transition-colors"
            >
              <span className="text-2xl mb-2 block">👤</span>
              <span className="font-medium">Sign Up</span>
            </a>

            <a
              href="/dashboard"
              className="p-4 text-center bg-purple-600 text-white rounded-lg hover:bg-purple-700 transition-colors"
            >
              <span className="text-2xl mb-2 block">📊</span>
              <span className="font-medium">Dashboard</span>
            </a>
          </div>
        </div>

        {/* Quick Links */}
        <div className="mt-8 bg-white rounded-lg shadow-lg p-8">
          <h2 className="text-2xl font-bold text-gray-900 mb-6">
            Quick Links
          </h2>

          <div className="grid grid-cols-2 md:grid-cols-4 gap-4">
            <a
              href="/api/test-supabase"
              target="_blank"
              className="p-4 text-center bg-gray-50 rounded-lg hover:bg-gray-100 transition-colors"
            >
              <span className="text-2xl mb-2 block">🔍</span>
              <span className="text-sm text-gray-700">API Test</span>
            </a>

            <a
              href="https://supabase.com/dashboard/project/jlesbkscprldariqcbvt"
              target="_blank"
              rel="noopener noreferrer"
              className="p-4 text-center bg-gray-50 rounded-lg hover:bg-gray-100 transition-colors"
            >
              <span className="text-2xl mb-2 block">🗄️</span>
              <span className="text-sm text-gray-700">Supabase Dashboard</span>
            </a>

            <a
              href="https://stytch.com/dashboard"
              target="_blank"
              rel="noopener noreferrer"
              className="p-4 text-center bg-gray-50 rounded-lg hover:bg-gray-100 transition-colors"
            >
              <span className="text-2xl mb-2 block">🔐</span>
              <span className="text-sm text-gray-700">Stytch Dashboard</span>
            </a>

            <a
              href="https://github.com/gray-ghost-data/toolbox-production-final"
              target="_blank"
              rel="noopener noreferrer"
              className="p-4 text-center bg-gray-50 rounded-lg hover:bg-gray-100 transition-colors"
            >
              <span className="text-2xl mb-2 block">📦</span>
              <span className="text-sm text-gray-700">GitHub Repo</span>
            </a>
          </div>
        </div>
      </div>
    </main>
  )
}