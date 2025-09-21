-- ================================================
-- ROW LEVEL SECURITY (RLS) POLICIES
-- ================================================
-- Enable RLS on all tables for enterprise-grade security

-- Enable RLS on all tables
ALTER TABLE users ENABLE ROW LEVEL SECURITY;
ALTER TABLE organizations ENABLE ROW LEVEL SECURITY;
ALTER TABLE projects ENABLE ROW LEVEL SECURITY;
ALTER TABLE tasks ENABLE ROW LEVEL SECURITY;
ALTER TABLE automations ENABLE ROW LEVEL SECURITY;
ALTER TABLE integrations ENABLE ROW LEVEL SECURITY;
ALTER TABLE activity_logs ENABLE ROW LEVEL SECURITY;
ALTER TABLE reports ENABLE ROW LEVEL SECURITY;
ALTER TABLE api_keys ENABLE ROW LEVEL SECURITY;

-- ================================================
-- HELPER FUNCTIONS
-- ================================================

-- Get current user's ID from JWT
CREATE OR REPLACE FUNCTION auth.user_id()
RETURNS INTEGER AS $$
BEGIN
    RETURN COALESCE(
        (current_setting('request.jwt.claims', true)::json->>'user_id')::INTEGER,
        (SELECT id FROM users WHERE stytch_user_id = auth.uid()::text LIMIT 1)
    );
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Get current user's organization ID
CREATE OR REPLACE FUNCTION auth.organization_id()
RETURNS INTEGER AS $$
BEGIN
    RETURN (
        SELECT organization_id
        FROM users
        WHERE id = auth.user_id()
        LIMIT 1
    );
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Check if user has specific role
CREATE OR REPLACE FUNCTION auth.has_role(required_role VARCHAR)
RETURNS BOOLEAN AS $$
BEGIN
    RETURN EXISTS (
        SELECT 1
        FROM users
        WHERE id = auth.user_id()
        AND role = required_role
    );
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Check if user is admin
CREATE OR REPLACE FUNCTION auth.is_admin()
RETURNS BOOLEAN AS $$
BEGIN
    RETURN auth.has_role('admin');
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Check if user is manager or admin
CREATE OR REPLACE FUNCTION auth.is_manager()
RETURNS BOOLEAN AS $$
BEGIN
    RETURN auth.has_role('manager') OR auth.has_role('admin');
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- ================================================
-- USERS TABLE POLICIES
-- ================================================

-- Users can view their own profile
CREATE POLICY "Users can view own profile" ON users
    FOR SELECT
    USING (id = auth.user_id());

-- Users can view other users in same organization
CREATE POLICY "Users can view organization members" ON users
    FOR SELECT
    USING (organization_id = auth.organization_id());

-- Users can update their own profile
CREATE POLICY "Users can update own profile" ON users
    FOR UPDATE
    USING (id = auth.user_id())
    WITH CHECK (id = auth.user_id() AND organization_id = auth.organization_id());

-- Admins can manage all users in organization
CREATE POLICY "Admins can manage organization users" ON users
    FOR ALL
    USING (
        auth.is_admin() AND
        organization_id = auth.organization_id()
    )
    WITH CHECK (
        auth.is_admin() AND
        organization_id = auth.organization_id()
    );

-- ================================================
-- ORGANIZATIONS TABLE POLICIES
-- ================================================

-- Users can view their organization
CREATE POLICY "Users can view own organization" ON organizations
    FOR SELECT
    USING (id = auth.organization_id());

-- Admins can update organization
CREATE POLICY "Admins can update organization" ON organizations
    FOR UPDATE
    USING (auth.is_admin() AND id = auth.organization_id())
    WITH CHECK (auth.is_admin() AND id = auth.organization_id());

-- ================================================
-- PROJECTS TABLE POLICIES
-- ================================================

-- Users can view projects in their organization
CREATE POLICY "Users can view organization projects" ON projects
    FOR SELECT
    USING (
        organization_id = auth.organization_id()
    );

-- Users can create projects in their organization
CREATE POLICY "Users can create projects" ON projects
    FOR INSERT
    WITH CHECK (
        organization_id = auth.organization_id() AND
        created_by = auth.user_id()
    );

-- Project creators and managers can update projects
CREATE POLICY "Project owners can update" ON projects
    FOR UPDATE
    USING (
        organization_id = auth.organization_id() AND
        (created_by = auth.user_id() OR auth.is_manager())
    )
    WITH CHECK (
        organization_id = auth.organization_id() AND
        (created_by = auth.user_id() OR auth.is_manager())
    );

-- Admins can delete projects
CREATE POLICY "Admins can delete projects" ON projects
    FOR DELETE
    USING (
        auth.is_admin() AND
        organization_id = auth.organization_id()
    );

-- ================================================
-- TASKS TABLE POLICIES
-- ================================================

-- Users can view tasks in their organization's projects
CREATE POLICY "Users can view organization tasks" ON tasks
    FOR SELECT
    USING (
        EXISTS (
            SELECT 1 FROM projects p
            WHERE p.id = tasks.project_id
            AND p.organization_id = auth.organization_id()
        )
    );

-- Users can create tasks in organization projects
CREATE POLICY "Users can create tasks" ON tasks
    FOR INSERT
    WITH CHECK (
        EXISTS (
            SELECT 1 FROM projects p
            WHERE p.id = project_id
            AND p.organization_id = auth.organization_id()
        ) AND
        created_by = auth.user_id()
    );

-- Assigned users and managers can update tasks
CREATE POLICY "Assigned users can update tasks" ON tasks
    FOR UPDATE
    USING (
        EXISTS (
            SELECT 1 FROM projects p
            WHERE p.id = tasks.project_id
            AND p.organization_id = auth.organization_id()
        ) AND
        (assigned_to = auth.user_id() OR created_by = auth.user_id() OR auth.is_manager())
    )
    WITH CHECK (
        EXISTS (
            SELECT 1 FROM projects p
            WHERE p.id = project_id
            AND p.organization_id = auth.organization_id()
        )
    );

-- Managers can delete tasks
CREATE POLICY "Managers can delete tasks" ON tasks
    FOR DELETE
    USING (
        auth.is_manager() AND
        EXISTS (
            SELECT 1 FROM projects p
            WHERE p.id = tasks.project_id
            AND p.organization_id = auth.organization_id()
        )
    );

-- ================================================
-- AUTOMATIONS TABLE POLICIES
-- ================================================

-- Users can view organization automations
CREATE POLICY "Users can view automations" ON automations
    FOR SELECT
    USING (
        EXISTS (
            SELECT 1 FROM projects p
            WHERE p.id = automations.project_id
            AND p.organization_id = auth.organization_id()
        )
    );

-- Managers can create automations
CREATE POLICY "Managers can create automations" ON automations
    FOR INSERT
    WITH CHECK (
        auth.is_manager() AND
        EXISTS (
            SELECT 1 FROM projects p
            WHERE p.id = project_id
            AND p.organization_id = auth.organization_id()
        ) AND
        created_by = auth.user_id()
    );

-- Managers can update automations
CREATE POLICY "Managers can update automations" ON automations
    FOR UPDATE
    USING (
        auth.is_manager() AND
        EXISTS (
            SELECT 1 FROM projects p
            WHERE p.id = automations.project_id
            AND p.organization_id = auth.organization_id()
        )
    );

-- Admins can delete automations
CREATE POLICY "Admins can delete automations" ON automations
    FOR DELETE
    USING (
        auth.is_admin() AND
        EXISTS (
            SELECT 1 FROM projects p
            WHERE p.id = automations.project_id
            AND p.organization_id = auth.organization_id()
        )
    );

-- ================================================
-- INTEGRATIONS TABLE POLICIES
-- ================================================

-- Users can view organization integrations
CREATE POLICY "Users can view integrations" ON integrations
    FOR SELECT
    USING (organization_id = auth.organization_id());

-- Admins can manage integrations
CREATE POLICY "Admins can manage integrations" ON integrations
    FOR ALL
    USING (
        auth.is_admin() AND
        organization_id = auth.organization_id()
    )
    WITH CHECK (
        auth.is_admin() AND
        organization_id = auth.organization_id()
    );

-- ================================================
-- ACTIVITY LOGS TABLE POLICIES
-- ================================================

-- Users can view their own activity
CREATE POLICY "Users can view own activity" ON activity_logs
    FOR SELECT
    USING (user_id = auth.user_id());

-- Managers can view organization activity
CREATE POLICY "Managers can view organization activity" ON activity_logs
    FOR SELECT
    USING (
        auth.is_manager() AND
        organization_id = auth.organization_id()
    );

-- System can insert activity logs (using service role)
CREATE POLICY "System can insert activity logs" ON activity_logs
    FOR INSERT
    WITH CHECK (true); -- Will be restricted by service role

-- ================================================
-- REPORTS TABLE POLICIES
-- ================================================

-- Users can view organization reports
CREATE POLICY "Users can view reports" ON reports
    FOR SELECT
    USING (organization_id = auth.organization_id());

-- Managers can create reports
CREATE POLICY "Managers can create reports" ON reports
    FOR INSERT
    WITH CHECK (
        auth.is_manager() AND
        organization_id = auth.organization_id() AND
        generated_by = auth.user_id()
    );

-- Report creators can update their reports
CREATE POLICY "Report creators can update" ON reports
    FOR UPDATE
    USING (
        organization_id = auth.organization_id() AND
        generated_by = auth.user_id()
    );

-- Admins can delete reports
CREATE POLICY "Admins can delete reports" ON reports
    FOR DELETE
    USING (
        auth.is_admin() AND
        organization_id = auth.organization_id()
    );

-- ================================================
-- API KEYS TABLE POLICIES
-- ================================================

-- Admins can view organization API keys
CREATE POLICY "Admins can view API keys" ON api_keys
    FOR SELECT
    USING (
        auth.is_admin() AND
        organization_id = auth.organization_id()
    );

-- Admins can manage API keys
CREATE POLICY "Admins can manage API keys" ON api_keys
    FOR ALL
    USING (
        auth.is_admin() AND
        organization_id = auth.organization_id()
    )
    WITH CHECK (
        auth.is_admin() AND
        organization_id = auth.organization_id() AND
        created_by = auth.user_id()
    );

-- ================================================
-- GRANT NECESSARY PERMISSIONS
-- ================================================

-- Grant usage on schema to authenticated users
GRANT USAGE ON SCHEMA public TO authenticated;

-- Grant permissions on tables to authenticated users
GRANT SELECT, INSERT, UPDATE, DELETE ON ALL TABLES IN SCHEMA public TO authenticated;

-- Grant permissions on sequences
GRANT USAGE, SELECT ON ALL SEQUENCES IN SCHEMA public TO authenticated;

-- Grant execute on functions
GRANT EXECUTE ON ALL FUNCTIONS IN SCHEMA public TO authenticated;
GRANT EXECUTE ON ALL FUNCTIONS IN SCHEMA auth TO authenticated;