import { createClient } from '@/utils/supabase/client'
import type { RealtimeChannel, RealtimePostgresChangesPayload } from '@supabase/supabase-js'
import type { Database } from '@/types/supabase'

type TableName = keyof Database['public']['Tables']

export interface RealtimeConfig<T extends TableName> {
  table: T
  filter?: {
    column: string
    operator?: 'eq' | 'neq' | 'gt' | 'gte' | 'lt' | 'lte' | 'like' | 'ilike' | 'in'
    value: any
  }
  organizationId?: number // Filter by organization for security
}

export interface RealtimeCallbacks<T extends TableName> {
  onInsert?: (record: Database['public']['Tables'][T]['Row']) => void
  onUpdate?: (record: Database['public']['Tables'][T]['Row']) => void
  onDelete?: (record: Database['public']['Tables'][T]['Row']) => void
  onError?: (error: Error) => void
}

/**
 * Supabase Realtime Manager
 * Manages real-time subscriptions for database changes
 */
export class SupabaseRealtimeManager {
  private supabase = createClient()
  private channels: Map<string, RealtimeChannel> = new Map()

  /**
   * Subscribe to real-time changes for a table
   */
  subscribe<T extends TableName>(
    config: RealtimeConfig<T>,
    callbacks: RealtimeCallbacks<T>
  ): string {
    const channelName = this.generateChannelName(config)

    // Avoid duplicate subscriptions
    if (this.channels.has(channelName)) {
      console.warn(`Already subscribed to channel: ${channelName}`)
      return channelName
    }

    try {
      // Build filter string
      let filter: string | undefined
      if (config.filter) {
        const { column, operator = 'eq', value } = config.filter
        filter = `${column}=${operator}.${value}`
      } else if (config.organizationId) {
        // Default organization filter for security
        filter = `organization_id=eq.${config.organizationId}`
      }

      // Create subscription channel
      const channel = this.supabase
        .channel(channelName)
        .on(
          'postgres_changes',
          {
            event: '*',
            schema: 'public',
            table: config.table,
            filter,
          },
          (payload: RealtimePostgresChangesPayload<any>) => {
            this.handleChange(payload, callbacks)
          }
        )
        .subscribe((status) => {
          if (status === 'SUBSCRIBED') {
            console.log(`Subscribed to real-time changes for ${config.table}`)
          } else if (status === 'CHANNEL_ERROR') {
            console.error(`Failed to subscribe to ${config.table}`)
            callbacks.onError?.(new Error('Subscription failed'))
          }
        })

      this.channels.set(channelName, channel)
      return channelName
    } catch (error) {
      console.error('Subscription error:', error)
      callbacks.onError?.(error as Error)
      return ''
    }
  }

  /**
   * Subscribe to multiple tables at once
   */
  subscribeMultiple(
    subscriptions: Array<{
      config: RealtimeConfig<any>
      callbacks: RealtimeCallbacks<any>
    }>
  ): string[] {
    return subscriptions.map(({ config, callbacks }) =>
      this.subscribe(config, callbacks)
    )
  }

  /**
   * Unsubscribe from a channel
   */
  unsubscribe(channelName: string): void {
    const channel = this.channels.get(channelName)
    if (channel) {
      this.supabase.removeChannel(channel)
      this.channels.delete(channelName)
      console.log(`Unsubscribed from channel: ${channelName}`)
    }
  }

  /**
   * Unsubscribe from all channels
   */
  unsubscribeAll(): void {
    this.channels.forEach((channel, name) => {
      this.supabase.removeChannel(channel)
      console.log(`Unsubscribed from channel: ${name}`)
    })
    this.channels.clear()
  }

  /**
   * Handle real-time change events
   */
  private handleChange<T extends TableName>(
    payload: RealtimePostgresChangesPayload<any>,
    callbacks: RealtimeCallbacks<T>
  ): void {
    try {
      switch (payload.eventType) {
        case 'INSERT':
          callbacks.onInsert?.(payload.new as Database['public']['Tables'][T]['Row'])
          break
        case 'UPDATE':
          callbacks.onUpdate?.(payload.new as Database['public']['Tables'][T]['Row'])
          break
        case 'DELETE':
          callbacks.onDelete?.(payload.old as Database['public']['Tables'][T]['Row'])
          break
      }
    } catch (error) {
      console.error('Error handling real-time change:', error)
      callbacks.onError?.(error as Error)
    }
  }

  /**
   * Generate unique channel name
   */
  private generateChannelName<T extends TableName>(config: RealtimeConfig<T>): string {
    let name = `realtime:${config.table}`
    if (config.filter) {
      name += `:${config.filter.column}:${config.filter.value}`
    } else if (config.organizationId) {
      name += `:org:${config.organizationId}`
    }
    return name
  }

  /**
   * Get list of active channels
   */
  getActiveChannels(): string[] {
    return Array.from(this.channels.keys())
  }
}

// Export singleton instance
export const realtimeManager = new SupabaseRealtimeManager()

// ================================================
// EXAMPLE USAGE FUNCTIONS
// ================================================

/**
 * Subscribe to task updates for a project
 */
export function subscribeToProjectTasks(
  projectId: number,
  callbacks: {
    onTaskAdded?: (task: Database['public']['Tables']['tasks']['Row']) => void
    onTaskUpdated?: (task: Database['public']['Tables']['tasks']['Row']) => void
    onTaskDeleted?: (task: Database['public']['Tables']['tasks']['Row']) => void
  }
): string {
  return realtimeManager.subscribe(
    {
      table: 'tasks',
      filter: {
        column: 'project_id',
        operator: 'eq',
        value: projectId,
      },
    },
    {
      onInsert: callbacks.onTaskAdded,
      onUpdate: callbacks.onTaskUpdated,
      onDelete: callbacks.onTaskDeleted,
    }
  )
}

/**
 * Subscribe to activity logs for an organization
 */
export function subscribeToOrganizationActivity(
  organizationId: number,
  callback: (activity: Database['public']['Tables']['activity_logs']['Row']) => void
): string {
  return realtimeManager.subscribe(
    {
      table: 'activity_logs',
      filter: {
        column: 'organization_id',
        operator: 'eq',
        value: organizationId,
      },
    },
    {
      onInsert: callback,
    }
  )
}

/**
 * Subscribe to automation status changes
 */
export function subscribeToAutomationStatus(
  automationId: string,
  onStatusChange: (automation: Database['public']['Tables']['automations']['Row']) => void
): string {
  return realtimeManager.subscribe(
    {
      table: 'automations',
      filter: {
        column: 'automation_id',
        operator: 'eq',
        value: automationId,
      },
    },
    {
      onUpdate: onStatusChange,
    }
  )
}

/**
 * Subscribe to new users joining organization
 */
export function subscribeToNewOrganizationMembers(
  organizationId: number,
  onNewMember: (user: Database['public']['Tables']['users']['Row']) => void
): string {
  return realtimeManager.subscribe(
    {
      table: 'users',
      filter: {
        column: 'organization_id',
        operator: 'eq',
        value: organizationId,
      },
    },
    {
      onInsert: onNewMember,
      onUpdate: onNewMember, // Also trigger when user's org is updated
    }
  )
}