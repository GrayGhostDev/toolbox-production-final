/**
 * TypeScript definitions for Supabase database schema
 * These types are based on the Toolbox database structure
 */

export type Json =
  | string
  | number
  | boolean
  | null
  | { [key: string]: Json | undefined }
  | Json[]

export interface Database {
  public: {
    Tables: {
      users: {
        Row: {
          id: number
          stytch_user_id: string
          email: string
          name: string | null
          avatar_url: string | null
          role: string
          organization_id: number | null
          metadata: Json
          created_at: string
          updated_at: string
          last_login_at: string | null
        }
        Insert: {
          id?: number
          stytch_user_id: string
          email: string
          name?: string | null
          avatar_url?: string | null
          role?: string
          organization_id?: number | null
          metadata?: Json
          created_at?: string
          updated_at?: string
          last_login_at?: string | null
        }
        Update: {
          id?: number
          stytch_user_id?: string
          email?: string
          name?: string | null
          avatar_url?: string | null
          role?: string
          organization_id?: number | null
          metadata?: Json
          created_at?: string
          updated_at?: string
          last_login_at?: string | null
        }
        Relationships: [
          {
            foreignKeyName: "users_organization_id_fkey"
            columns: ["organization_id"]
            referencedRelation: "organizations"
            referencedColumns: ["id"]
          }
        ]
      }
      organizations: {
        Row: {
          id: number
          stytch_org_id: string
          name: string
          slug: string
          domain: string | null
          settings: Json
          subscription_tier: string
          created_at: string
          updated_at: string
        }
        Insert: {
          id?: number
          stytch_org_id: string
          name: string
          slug: string
          domain?: string | null
          settings?: Json
          subscription_tier?: string
          created_at?: string
          updated_at?: string
        }
        Update: {
          id?: number
          stytch_org_id?: string
          name?: string
          slug?: string
          domain?: string | null
          settings?: Json
          subscription_tier?: string
          created_at?: string
          updated_at?: string
        }
        Relationships: []
      }
      projects: {
        Row: {
          id: number
          project_id: string
          organization_id: number | null
          name: string
          description: string | null
          status: string
          settings: Json
          created_by: number | null
          created_at: string
          updated_at: string
        }
        Insert: {
          id?: number
          project_id: string
          organization_id?: number | null
          name: string
          description?: string | null
          status?: string
          settings?: Json
          created_by?: number | null
          created_at?: string
          updated_at?: string
        }
        Update: {
          id?: number
          project_id?: string
          organization_id?: number | null
          name?: string
          description?: string | null
          status?: string
          settings?: Json
          created_by?: number | null
          created_at?: string
          updated_at?: string
        }
        Relationships: [
          {
            foreignKeyName: "projects_organization_id_fkey"
            columns: ["organization_id"]
            referencedRelation: "organizations"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "projects_created_by_fkey"
            columns: ["created_by"]
            referencedRelation: "users"
            referencedColumns: ["id"]
          }
        ]
      }
      tasks: {
        Row: {
          id: number
          task_id: string
          project_id: number | null
          assigned_to: number | null
          title: string
          description: string | null
          status: string
          priority: string
          due_date: string | null
          completed_at: string | null
          metadata: Json
          created_by: number | null
          created_at: string
          updated_at: string
        }
        Insert: {
          id?: number
          task_id: string
          project_id?: number | null
          assigned_to?: number | null
          title: string
          description?: string | null
          status?: string
          priority?: string
          due_date?: string | null
          completed_at?: string | null
          metadata?: Json
          created_by?: number | null
          created_at?: string
          updated_at?: string
        }
        Update: {
          id?: number
          task_id?: string
          project_id?: number | null
          assigned_to?: number | null
          title?: string
          description?: string | null
          status?: string
          priority?: string
          due_date?: string | null
          completed_at?: string | null
          metadata?: Json
          created_by?: number | null
          created_at?: string
          updated_at?: string
        }
        Relationships: [
          {
            foreignKeyName: "tasks_project_id_fkey"
            columns: ["project_id"]
            referencedRelation: "projects"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "tasks_assigned_to_fkey"
            columns: ["assigned_to"]
            referencedRelation: "users"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "tasks_created_by_fkey"
            columns: ["created_by"]
            referencedRelation: "users"
            referencedColumns: ["id"]
          }
        ]
      }
      automations: {
        Row: {
          id: number
          automation_id: string
          project_id: number | null
          name: string
          trigger_type: string
          trigger_config: Json
          actions: Json
          is_enabled: boolean
          last_run_at: string | null
          run_count: number
          created_by: number | null
          created_at: string
          updated_at: string
        }
        Insert: {
          id?: number
          automation_id: string
          project_id?: number | null
          name: string
          trigger_type: string
          trigger_config: Json
          actions: Json
          is_enabled?: boolean
          last_run_at?: string | null
          run_count?: number
          created_by?: number | null
          created_at?: string
          updated_at?: string
        }
        Update: {
          id?: number
          automation_id?: string
          project_id?: number | null
          name?: string
          trigger_type?: string
          trigger_config?: Json
          actions?: Json
          is_enabled?: boolean
          last_run_at?: string | null
          run_count?: number
          created_by?: number | null
          created_at?: string
          updated_at?: string
        }
        Relationships: [
          {
            foreignKeyName: "automations_project_id_fkey"
            columns: ["project_id"]
            referencedRelation: "projects"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "automations_created_by_fkey"
            columns: ["created_by"]
            referencedRelation: "users"
            referencedColumns: ["id"]
          }
        ]
      }
      integrations: {
        Row: {
          id: number
          organization_id: number | null
          service_name: string
          service_type: string
          credentials: Json | null
          settings: Json
          is_active: boolean
          last_sync_at: string | null
          created_at: string
          updated_at: string
        }
        Insert: {
          id?: number
          organization_id?: number | null
          service_name: string
          service_type: string
          credentials?: Json | null
          settings?: Json
          is_active?: boolean
          last_sync_at?: string | null
          created_at?: string
          updated_at?: string
        }
        Update: {
          id?: number
          organization_id?: number | null
          service_name?: string
          service_type?: string
          credentials?: Json | null
          settings?: Json
          is_active?: boolean
          last_sync_at?: string | null
          created_at?: string
          updated_at?: string
        }
        Relationships: [
          {
            foreignKeyName: "integrations_organization_id_fkey"
            columns: ["organization_id"]
            referencedRelation: "organizations"
            referencedColumns: ["id"]
          }
        ]
      }
      activity_logs: {
        Row: {
          id: number
          user_id: number | null
          organization_id: number | null
          action: string
          resource_type: string | null
          resource_id: string | null
          details: Json | null
          ip_address: string | null
          user_agent: string | null
          created_at: string
        }
        Insert: {
          id?: number
          user_id?: number | null
          organization_id?: number | null
          action: string
          resource_type?: string | null
          resource_id?: string | null
          details?: Json | null
          ip_address?: string | null
          user_agent?: string | null
          created_at?: string
        }
        Update: {
          id?: number
          user_id?: number | null
          organization_id?: number | null
          action?: string
          resource_type?: string | null
          resource_id?: string | null
          details?: Json | null
          ip_address?: string | null
          user_agent?: string | null
          created_at?: string
        }
        Relationships: [
          {
            foreignKeyName: "activity_logs_user_id_fkey"
            columns: ["user_id"]
            referencedRelation: "users"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "activity_logs_organization_id_fkey"
            columns: ["organization_id"]
            referencedRelation: "organizations"
            referencedColumns: ["id"]
          }
        ]
      }
      reports: {
        Row: {
          id: number
          report_id: string
          organization_id: number | null
          name: string
          type: string
          parameters: Json
          data: Json | null
          generated_by: number | null
          generated_at: string
        }
        Insert: {
          id?: number
          report_id: string
          organization_id?: number | null
          name: string
          type: string
          parameters?: Json
          data?: Json | null
          generated_by?: number | null
          generated_at?: string
        }
        Update: {
          id?: number
          report_id?: string
          organization_id?: number | null
          name?: string
          type?: string
          parameters?: Json
          data?: Json | null
          generated_by?: number | null
          generated_at?: string
        }
        Relationships: [
          {
            foreignKeyName: "reports_organization_id_fkey"
            columns: ["organization_id"]
            referencedRelation: "organizations"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "reports_generated_by_fkey"
            columns: ["generated_by"]
            referencedRelation: "users"
            referencedColumns: ["id"]
          }
        ]
      }
      api_keys: {
        Row: {
          id: number
          key_id: string
          organization_id: number | null
          name: string
          key_hash: string
          permissions: Json
          last_used_at: string | null
          expires_at: string | null
          is_active: boolean
          created_by: number | null
          created_at: string
        }
        Insert: {
          id?: number
          key_id: string
          organization_id?: number | null
          name: string
          key_hash: string
          permissions?: Json
          last_used_at?: string | null
          expires_at?: string | null
          is_active?: boolean
          created_by?: number | null
          created_at?: string
        }
        Update: {
          id?: number
          key_id?: string
          organization_id?: number | null
          name?: string
          key_hash?: string
          permissions?: Json
          last_used_at?: string | null
          expires_at?: string | null
          is_active?: boolean
          created_by?: number | null
          created_at?: string
        }
        Relationships: [
          {
            foreignKeyName: "api_keys_organization_id_fkey"
            columns: ["organization_id"]
            referencedRelation: "organizations"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "api_keys_created_by_fkey"
            columns: ["created_by"]
            referencedRelation: "users"
            referencedColumns: ["id"]
          }
        ]
      }
    }
    Views: {}
    Functions: {
      user_id: {
        Args: {}
        Returns: number
      }
      organization_id: {
        Args: {}
        Returns: number
      }
      has_role: {
        Args: {
          required_role: string
        }
        Returns: boolean
      }
      is_admin: {
        Args: {}
        Returns: boolean
      }
      is_manager: {
        Args: {}
        Returns: boolean
      }
    }
    Enums: {}
  }
}

// Helper types for easier usage
export type Tables<T extends keyof Database['public']['Tables']> = Database['public']['Tables'][T]['Row']
export type InsertTables<T extends keyof Database['public']['Tables']> = Database['public']['Tables'][T]['Insert']
export type UpdateTables<T extends keyof Database['public']['Tables']> = Database['public']['Tables'][T]['Update']

// Specific table types
export type User = Tables<'users'>
export type Organization = Tables<'organizations'>
export type Project = Tables<'projects'>
export type Task = Tables<'tasks'>
export type Automation = Tables<'automations'>
export type Integration = Tables<'integrations'>
export type ActivityLog = Tables<'activity_logs'>
export type Report = Tables<'reports'>
export type ApiKey = Tables<'api_keys'>