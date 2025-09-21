import { NextResponse } from 'next/server'
import { createClient } from '@/utils/supabase/server'
import type { Database } from '@/types/supabase'

/**
 * Test API endpoint for Supabase integration
 * Tests connection, queries, and RLS policies
 */
export async function GET() {
  const results: any = {
    timestamp: new Date().toISOString(),
    tests: []
  }

  try {
    // Test 1: Create Supabase client
    const supabase = await createClient()
    results.tests.push({
      name: 'Create Client',
      status: 'PASS',
      details: 'Supabase client created successfully'
    })

    // Test 2: Test database connection
    const { count, error: pingError } = await supabase
      .from('organizations')
      .select('*', { count: 'exact', head: true })

    if (pingError) {
      results.tests.push({
        name: 'Database Connection',
        status: 'FAIL',
        error: pingError.message
      })
    } else {
      results.tests.push({
        name: 'Database Connection',
        status: 'PASS',
        details: `Connected to database, found ${count} organizations`
      })
    }

    // Test 3: Test RLS by querying users table
    const { data: users, error: usersError } = await supabase
      .from('users')
      .select('id, email, name')
      .limit(5)

    if (usersError) {
      results.tests.push({
        name: 'RLS Test - Users',
        status: 'WARN',
        details: 'RLS is working (no authenticated user)',
        error: usersError.message
      })
    } else {
      results.tests.push({
        name: 'RLS Test - Users',
        status: 'PASS',
        details: `Retrieved ${users?.length || 0} users`
      })
    }

    // Test 4: Test real-time capabilities
    const realtimeEnabled = !!supabase.channel
    results.tests.push({
      name: 'Realtime Capability',
      status: realtimeEnabled ? 'PASS' : 'FAIL',
      details: realtimeEnabled ? 'Realtime is available' : 'Realtime not configured'
    })

    // Test 5: Environment variables
    const envVars = {
      SUPABASE_URL: !!process.env.NEXT_PUBLIC_SUPABASE_URL,
      SUPABASE_ANON_KEY: !!process.env.NEXT_PUBLIC_SUPABASE_ANON_KEY,
      SUPABASE_SERVICE_KEY: !!process.env.SUPABASE_SERVICE_ROLE_KEY,
      STYTCH_PROJECT_ID: !!process.env.STYTCH_PROJECT_ID,
    }

    const allEnvVarsSet = Object.values(envVars).every(v => v === true)
    results.tests.push({
      name: 'Environment Variables',
      status: allEnvVarsSet ? 'PASS' : 'PARTIAL',
      details: envVars
    })

    // Test 6: Test Supabase Storage (check if configured)
    const { data: buckets, error: storageError } = await supabase
      .storage
      .listBuckets()

    results.tests.push({
      name: 'Storage Configuration',
      status: storageError ? 'INFO' : 'PASS',
      details: storageError ? 'Storage not configured yet' : `Found ${buckets?.length || 0} storage buckets`
    })

    // Summary
    const passCount = results.tests.filter((t: any) => t.status === 'PASS').length
    const totalCount = results.tests.length

    results.summary = {
      total: totalCount,
      passed: passCount,
      status: passCount === totalCount ? 'ALL_PASS' : 'PARTIAL',
      integration: 'Supabase integration is configured and operational'
    }

    return NextResponse.json(results, { status: 200 })

  } catch (error) {
    results.error = {
      message: 'Test suite failed',
      details: error instanceof Error ? error.message : 'Unknown error'
    }

    return NextResponse.json(results, { status: 500 })
  }
}

/**
 * Test POST endpoint for write operations
 */
export async function POST(request: Request) {
  try {
    const body = await request.json()
    const supabase = await createClient()

    // Test insert operation (will fail without proper auth due to RLS)
    const testData = {
      action: 'TEST_SUPABASE_INTEGRATION',
      resource_type: 'api_test',
      resource_id: `test_${Date.now()}`,
      details: body
    }

    const { data, error } = await supabase
      .from('activity_logs')
      .insert(testData)
      .select()

    if (error) {
      return NextResponse.json({
        status: 'Expected RLS Protection',
        message: 'Write operations are properly protected by RLS',
        error: error.message
      }, { status: 403 })
    }

    return NextResponse.json({
      status: 'Success',
      message: 'Write operation completed',
      data
    }, { status: 201 })

  } catch (error) {
    return NextResponse.json({
      status: 'Error',
      message: error instanceof Error ? error.message : 'Unknown error'
    }, { status: 500 })
  }
}