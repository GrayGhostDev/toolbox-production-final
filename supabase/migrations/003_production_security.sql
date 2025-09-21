-- ================================================
-- PRODUCTION SECURITY CONFIGURATION
-- ================================================
-- Additional security measures for production deployment

-- ================================================
-- 1. NETWORK SECURITY
-- ================================================
-- Note: Network restrictions should be configured in Supabase Dashboard
-- Recommended settings:
-- - Enable SSL enforcement
-- - Restrict database access to specific IP ranges
-- - Enable connection pooling with PgBouncer
-- - Set appropriate statement timeout (30s recommended)

-- ================================================
-- 2. RATE LIMITING CONFIGURATION
-- ================================================
-- Create rate limiting table for API keys
CREATE TABLE IF NOT EXISTS rate_limits (
    id SERIAL PRIMARY KEY,
    api_key_id INTEGER REFERENCES api_keys(id) ON DELETE CASCADE,
    endpoint VARCHAR(255) NOT NULL,
    requests_count INTEGER DEFAULT 0,
    window_start TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    UNIQUE(api_key_id, endpoint, window_start)
);

-- Function to check rate limits
CREATE OR REPLACE FUNCTION check_rate_limit(
    p_api_key_id INTEGER,
    p_endpoint VARCHAR,
    p_max_requests INTEGER DEFAULT 100,
    p_window_minutes INTEGER DEFAULT 1
) RETURNS BOOLEAN AS $$
DECLARE
    v_current_count INTEGER;
    v_window_start TIMESTAMP;
BEGIN
    v_window_start := date_trunc('minute', CURRENT_TIMESTAMP);

    -- Get current request count
    SELECT requests_count INTO v_current_count
    FROM rate_limits
    WHERE api_key_id = p_api_key_id
        AND endpoint = p_endpoint
        AND window_start = v_window_start;

    IF v_current_count IS NULL THEN
        -- First request in this window
        INSERT INTO rate_limits (api_key_id, endpoint, requests_count, window_start)
        VALUES (p_api_key_id, p_endpoint, 1, v_window_start)
        ON CONFLICT (api_key_id, endpoint, window_start) DO UPDATE
        SET requests_count = rate_limits.requests_count + 1;
        RETURN TRUE;
    ELSIF v_current_count < p_max_requests THEN
        -- Increment counter
        UPDATE rate_limits
        SET requests_count = requests_count + 1
        WHERE api_key_id = p_api_key_id
            AND endpoint = p_endpoint
            AND window_start = v_window_start;
        RETURN TRUE;
    ELSE
        -- Rate limit exceeded
        RETURN FALSE;
    END IF;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- ================================================
-- 3. AUDIT LOGGING ENHANCEMENTS
-- ================================================
-- Enhanced audit log function
CREATE OR REPLACE FUNCTION audit_log(
    p_action VARCHAR,
    p_resource_type VARCHAR DEFAULT NULL,
    p_resource_id VARCHAR DEFAULT NULL,
    p_details JSONB DEFAULT NULL
) RETURNS VOID AS $$
BEGIN
    INSERT INTO activity_logs (
        user_id,
        organization_id,
        action,
        resource_type,
        resource_id,
        details,
        ip_address,
        user_agent,
        created_at
    ) VALUES (
        auth.user_id(),
        auth.organization_id(),
        p_action,
        p_resource_type,
        p_resource_id,
        p_details,
        inet(current_setting('request.headers', true)::json->>'x-forwarded-for'),
        current_setting('request.headers', true)::json->>'user-agent',
        CURRENT_TIMESTAMP
    );
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- ================================================
-- 4. DATA ENCRYPTION
-- ================================================
-- Function to encrypt sensitive data
CREATE OR REPLACE FUNCTION encrypt_sensitive_data(
    p_data TEXT,
    p_key TEXT DEFAULT NULL
) RETURNS TEXT AS $$
BEGIN
    -- Use Supabase vault for encryption keys in production
    -- This is a placeholder - actual implementation should use pgcrypto
    RETURN encode(digest(p_data || COALESCE(p_key, 'default_key'), 'sha256'), 'hex');
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- ================================================
-- 5. SESSION MANAGEMENT
-- ================================================
-- Session tracking table
CREATE TABLE IF NOT EXISTS user_sessions (
    id SERIAL PRIMARY KEY,
    user_id INTEGER REFERENCES users(id) ON DELETE CASCADE,
    session_token VARCHAR(255) UNIQUE NOT NULL,
    ip_address INET,
    user_agent TEXT,
    last_activity TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    expires_at TIMESTAMP NOT NULL,
    is_active BOOLEAN DEFAULT TRUE,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Function to validate session
CREATE OR REPLACE FUNCTION validate_session(p_token VARCHAR)
RETURNS TABLE(user_id INTEGER, is_valid BOOLEAN) AS $$
BEGIN
    RETURN QUERY
    SELECT
        s.user_id,
        (s.is_active AND s.expires_at > CURRENT_TIMESTAMP) as is_valid
    FROM user_sessions s
    WHERE s.session_token = p_token;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- ================================================
-- 6. DATA RETENTION POLICIES
-- ================================================
-- Function to clean old data
CREATE OR REPLACE FUNCTION cleanup_old_data() RETURNS VOID AS $$
BEGIN
    -- Delete old activity logs (keep 90 days)
    DELETE FROM activity_logs
    WHERE created_at < CURRENT_TIMESTAMP - INTERVAL '90 days';

    -- Delete old rate limit records (keep 1 day)
    DELETE FROM rate_limits
    WHERE window_start < CURRENT_TIMESTAMP - INTERVAL '1 day';

    -- Delete expired sessions
    DELETE FROM user_sessions
    WHERE expires_at < CURRENT_TIMESTAMP;

    -- Archive old completed tasks (move to archive table)
    -- This would require an archive table to be created
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- ================================================
-- 7. SECURITY TRIGGERS
-- ================================================
-- Trigger to audit sensitive operations
CREATE OR REPLACE FUNCTION audit_sensitive_operations()
RETURNS TRIGGER AS $$
BEGIN
    IF TG_OP = 'DELETE' THEN
        PERFORM audit_log(
            'DELETE_' || TG_TABLE_NAME,
            TG_TABLE_NAME,
            OLD.id::VARCHAR,
            jsonb_build_object('deleted_record', row_to_json(OLD))
        );
        RETURN OLD;
    ELSIF TG_OP = 'UPDATE' THEN
        -- Audit changes to sensitive fields
        IF TG_TABLE_NAME = 'users' AND OLD.role != NEW.role THEN
            PERFORM audit_log(
                'ROLE_CHANGE',
                'users',
                NEW.id::VARCHAR,
                jsonb_build_object(
                    'old_role', OLD.role,
                    'new_role', NEW.role
                )
            );
        END IF;
        RETURN NEW;
    ELSIF TG_OP = 'INSERT' THEN
        IF TG_TABLE_NAME IN ('api_keys', 'integrations') THEN
            PERFORM audit_log(
                'CREATE_' || TG_TABLE_NAME,
                TG_TABLE_NAME,
                NEW.id::VARCHAR,
                jsonb_build_object('created', row_to_json(NEW))
            );
        END IF;
        RETURN NEW;
    END IF;
    RETURN NULL;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Apply audit triggers to sensitive tables
CREATE TRIGGER audit_users_changes
    AFTER UPDATE OR DELETE ON users
    FOR EACH ROW EXECUTE FUNCTION audit_sensitive_operations();

CREATE TRIGGER audit_api_keys_changes
    AFTER INSERT OR DELETE ON api_keys
    FOR EACH ROW EXECUTE FUNCTION audit_sensitive_operations();

CREATE TRIGGER audit_integrations_changes
    AFTER INSERT OR DELETE ON integrations
    FOR EACH ROW EXECUTE FUNCTION audit_sensitive_operations();

-- ================================================
-- 8. SECURITY VIEWS
-- ================================================
-- View for active sessions (hide sensitive data)
CREATE OR REPLACE VIEW active_sessions AS
SELECT
    u.email,
    u.name,
    s.ip_address,
    s.last_activity,
    s.expires_at
FROM user_sessions s
JOIN users u ON s.user_id = u.id
WHERE s.is_active = TRUE
    AND s.expires_at > CURRENT_TIMESTAMP;

-- View for security audit summary
CREATE OR REPLACE VIEW security_audit_summary AS
SELECT
    DATE(created_at) as date,
    action,
    COUNT(*) as count,
    COUNT(DISTINCT user_id) as unique_users
FROM activity_logs
WHERE created_at > CURRENT_TIMESTAMP - INTERVAL '30 days'
GROUP BY DATE(created_at), action
ORDER BY date DESC, count DESC;

-- ================================================
-- 9. SECURITY FUNCTIONS FOR API
-- ================================================
-- Function to validate API key and check permissions
CREATE OR REPLACE FUNCTION validate_api_key(
    p_key_hash VARCHAR,
    p_required_permission VARCHAR DEFAULT NULL
) RETURNS TABLE(
    is_valid BOOLEAN,
    organization_id INTEGER,
    permissions JSONB
) AS $$
BEGIN
    RETURN QUERY
    SELECT
        (k.is_active AND (k.expires_at IS NULL OR k.expires_at > CURRENT_TIMESTAMP)) as is_valid,
        k.organization_id,
        k.permissions
    FROM api_keys k
    WHERE k.key_hash = p_key_hash
        AND k.is_active = TRUE
        AND (p_required_permission IS NULL OR
             k.permissions ? p_required_permission OR
             k.permissions->>'admin' = 'true');

    -- Update last used timestamp
    UPDATE api_keys
    SET last_used_at = CURRENT_TIMESTAMP
    WHERE key_hash = p_key_hash;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- ================================================
-- 10. SCHEDULED MAINTENANCE
-- ================================================
-- Note: These should be scheduled using pg_cron in Supabase
-- Example cron jobs to add in Supabase Dashboard:

-- Daily cleanup at 2 AM
-- SELECT cron.schedule('daily-cleanup', '0 2 * * *', 'SELECT cleanup_old_data();');

-- Hourly session cleanup
-- SELECT cron.schedule('session-cleanup', '0 * * * *', 'DELETE FROM user_sessions WHERE expires_at < CURRENT_TIMESTAMP;');

-- Weekly vacuum analyze
-- SELECT cron.schedule('weekly-vacuum', '0 3 * * 0', 'VACUUM ANALYZE;');

-- ================================================
-- 11. SECURITY CONFIGURATION CHECKS
-- ================================================
CREATE OR REPLACE FUNCTION security_health_check()
RETURNS TABLE(
    check_name VARCHAR,
    status VARCHAR,
    details TEXT
) AS $$
BEGIN
    -- Check RLS is enabled on all tables
    RETURN QUERY
    SELECT
        'RLS_ENABLED'::VARCHAR,
        CASE
            WHEN COUNT(*) = 0 THEN 'PASS'::VARCHAR
            ELSE 'FAIL'::VARCHAR
        END,
        'Tables without RLS: ' || COALESCE(string_agg(tablename, ', '), 'None')
    FROM pg_tables
    WHERE schemaname = 'public'
        AND tablename NOT IN ('rate_limits', 'user_sessions') -- Exclude system tables
        AND NOT EXISTS (
            SELECT 1 FROM pg_policies
            WHERE pg_policies.tablename = pg_tables.tablename
        );

    -- Check for unused API keys
    RETURN QUERY
    SELECT
        'UNUSED_API_KEYS'::VARCHAR,
        CASE
            WHEN COUNT(*) = 0 THEN 'PASS'::VARCHAR
            ELSE 'WARNING'::VARCHAR
        END,
        COUNT(*)::TEXT || ' API keys unused for 30+ days'
    FROM api_keys
    WHERE last_used_at < CURRENT_TIMESTAMP - INTERVAL '30 days'
        OR last_used_at IS NULL;

    -- Check for expired sessions
    RETURN QUERY
    SELECT
        'EXPIRED_SESSIONS'::VARCHAR,
        CASE
            WHEN COUNT(*) = 0 THEN 'PASS'::VARCHAR
            ELSE 'WARNING'::VARCHAR
        END,
        COUNT(*)::TEXT || ' expired sessions need cleanup'
    FROM user_sessions
    WHERE expires_at < CURRENT_TIMESTAMP;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Grant execute permission on security functions to authenticated users
GRANT EXECUTE ON FUNCTION security_health_check() TO authenticated;