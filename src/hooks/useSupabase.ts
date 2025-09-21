import { useState, useEffect } from 'react'
import { createClient } from '@/utils/supabase/client'
import { authBridge } from '@/lib/auth/stytch-supabase-bridge'
import type { SupabaseClient } from '@supabase/supabase-js'

interface UseSupabaseReturn {
  supabase: SupabaseClient
  user: any | null
  loading: boolean
  error: Error | null
}

/**
 * Hook to use Supabase client with Stytch authentication
 */
export function useSupabase(): UseSupabaseReturn {
  const [user, setUser] = useState<any | null>(null)
  const [loading, setLoading] = useState(true)
  const [error, setError] = useState<Error | null>(null)

  const supabase = createClient()

  useEffect(() => {
    const loadUser = async () => {
      try {
        setLoading(true)

        // Verify session with Stytch
        const isValid = await authBridge.verifySession()

        if (isValid) {
          // Get current user from bridge
          const currentUser = await authBridge.getCurrentUser()
          setUser(currentUser)
        } else {
          setUser(null)
        }
      } catch (err) {
        console.error('Failed to load user:', err)
        setError(err as Error)
      } finally {
        setLoading(false)
      }
    }

    loadUser()
  }, [])

  return {
    supabase,
    user,
    loading,
    error,
  }
}

/**
 * Hook for real-time subscriptions
 */
export function useRealtimeSubscription(
  table: string,
  filter?: { column: string; value: any },
  onInsert?: (payload: any) => void,
  onUpdate?: (payload: any) => void,
  onDelete?: (payload: any) => void
) {
  const supabase = createClient()

  useEffect(() => {
    const channel = supabase
      .channel(`${table}_changes`)
      .on(
        'postgres_changes',
        {
          event: '*',
          schema: 'public',
          table,
          filter: filter ? `${filter.column}=eq.${filter.value}` : undefined,
        },
        (payload) => {
          switch (payload.eventType) {
            case 'INSERT':
              onInsert?.(payload.new)
              break
            case 'UPDATE':
              onUpdate?.(payload.new)
              break
            case 'DELETE':
              onDelete?.(payload.old)
              break
          }
        }
      )
      .subscribe()

    return () => {
      supabase.removeChannel(channel)
    }
  }, [table, filter, onInsert, onUpdate, onDelete])
}

/**
 * Hook for Supabase queries with loading state
 */
export function useSupabaseQuery<T = any>(
  queryFn: (supabase: SupabaseClient) => Promise<{ data: T | null; error: any }>,
  dependencies: any[] = []
) {
  const [data, setData] = useState<T | null>(null)
  const [loading, setLoading] = useState(true)
  const [error, setError] = useState<Error | null>(null)

  const supabase = createClient()

  useEffect(() => {
    const fetchData = async () => {
      try {
        setLoading(true)
        const result = await queryFn(supabase)

        if (result.error) {
          throw result.error
        }

        setData(result.data)
      } catch (err) {
        console.error('Query failed:', err)
        setError(err as Error)
      } finally {
        setLoading(false)
      }
    }

    fetchData()
  }, dependencies)

  return { data, loading, error, refetch: () => fetchData() }
}