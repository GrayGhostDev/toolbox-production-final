#!/bin/bash

# ================================================
# DATABASE INITIALIZATION SCRIPT FOR CURSOR IDE
# ================================================
# This script creates and configures PostgreSQL databases
# for the Cursor IDE development environment

set -e  # Exit on error

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Configuration
POSTGRES_USER="${POSTGRES_USER:-grayghostdata}"
POSTGRES_PASSWORD="${POSTGRES_PASSWORD:-postgres}"
POSTGRES_HOST="${POSTGRES_HOST:-localhost}"
POSTGRES_PORT="${POSTGRES_PORT:-5432}"

# Database names
DEV_DB="cursor_development"
TEST_DB="cursor_test"
PROD_DB="cursor_production"
PROJECT_DB="cursor_project"

# Function to print colored output
print_status() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

print_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

print_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

# Function to check if PostgreSQL is running
check_postgres() {
    print_status "Checking PostgreSQL connection..."

    if PGPASSWORD=$POSTGRES_PASSWORD psql -h $POSTGRES_HOST -p $POSTGRES_PORT -U $POSTGRES_USER -lqt 2>/dev/null; then
        print_success "PostgreSQL is running and accessible"
        return 0
    else
        print_error "Cannot connect to PostgreSQL"
        print_status "Attempting to start PostgreSQL..."

        # Try to start PostgreSQL based on the system
        if [[ "$OSTYPE" == "darwin"* ]]; then
            # macOS
            if command -v brew &> /dev/null; then
                brew services start postgresql@16 || true
            fi
        elif [[ "$OSTYPE" == "linux-gnu"* ]]; then
            # Linux
            sudo systemctl start postgresql || true
        fi

        sleep 3

        # Check again
        if PGPASSWORD=$POSTGRES_PASSWORD psql -h $POSTGRES_HOST -p $POSTGRES_PORT -U $POSTGRES_USER -lqt 2>/dev/null; then
            print_success "PostgreSQL started successfully"
            return 0
        else
            print_error "Failed to start PostgreSQL. Please start it manually."
            return 1
        fi
    fi
}

# Function to create database if it doesn't exist
create_database() {
    local db_name=$1
    local db_description=$2

    print_status "Checking database: $db_name..."

    if PGPASSWORD=$POSTGRES_PASSWORD psql -h $POSTGRES_HOST -p $POSTGRES_PORT -U $POSTGRES_USER -lqt | cut -d \| -f 1 | grep -qw "$db_name"; then
        print_warning "Database '$db_name' already exists"
    else
        print_status "Creating database: $db_name ($db_description)..."
        PGPASSWORD=$POSTGRES_PASSWORD psql -h $POSTGRES_HOST -p $POSTGRES_PORT -U $POSTGRES_USER -c "CREATE DATABASE $db_name;"

        if [ $? -eq 0 ]; then
            print_success "Database '$db_name' created successfully"
        else
            print_error "Failed to create database '$db_name'"
            return 1
        fi
    fi

    # Grant all privileges to the user
    PGPASSWORD=$POSTGRES_PASSWORD psql -h $POSTGRES_HOST -p $POSTGRES_PORT -U $POSTGRES_USER -c "GRANT ALL PRIVILEGES ON DATABASE $db_name TO $POSTGRES_USER;" 2>/dev/null || true
}

# Function to create tables for cursor configuration
create_cursor_tables() {
    local db_name=$1

    print_status "Creating tables in $db_name..."

    PGPASSWORD=$POSTGRES_PASSWORD psql -h $POSTGRES_HOST -p $POSTGRES_PORT -U $POSTGRES_USER -d $db_name <<EOF
-- Stytch authentication sessions
CREATE TABLE IF NOT EXISTS auth_sessions (
    id SERIAL PRIMARY KEY,
    session_id VARCHAR(255) UNIQUE NOT NULL,
    user_id VARCHAR(255) NOT NULL,
    email VARCHAR(255),
    workspace_id VARCHAR(255),
    project_id VARCHAR(255),
    expires_at TIMESTAMP NOT NULL,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Workspace configurations
CREATE TABLE IF NOT EXISTS workspace_configs (
    id SERIAL PRIMARY KEY,
    workspace_id VARCHAR(255) UNIQUE NOT NULL,
    workspace_name VARCHAR(255) NOT NULL,
    workspace_slug VARCHAR(255) UNIQUE NOT NULL,
    config_data JSONB NOT NULL,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Project configurations
CREATE TABLE IF NOT EXISTS project_configs (
    id SERIAL PRIMARY KEY,
    project_id VARCHAR(255) UNIQUE NOT NULL,
    workspace_id VARCHAR(255) REFERENCES workspace_configs(workspace_id),
    project_name VARCHAR(255) NOT NULL,
    project_domain VARCHAR(255),
    environment VARCHAR(50) NOT NULL,
    config_data JSONB NOT NULL,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Audit logs
CREATE TABLE IF NOT EXISTS audit_logs (
    id SERIAL PRIMARY KEY,
    user_id VARCHAR(255),
    action VARCHAR(255) NOT NULL,
    resource_type VARCHAR(100),
    resource_id VARCHAR(255),
    details JSONB,
    ip_address INET,
    user_agent TEXT,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- MCP server configurations
CREATE TABLE IF NOT EXISTS mcp_servers (
    id SERIAL PRIMARY KEY,
    server_name VARCHAR(100) UNIQUE NOT NULL,
    server_type VARCHAR(50) NOT NULL,
    configuration JSONB NOT NULL,
    is_active BOOLEAN DEFAULT true,
    health_status VARCHAR(50) DEFAULT 'unknown',
    last_health_check TIMESTAMP,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Slack integration data
CREATE TABLE IF NOT EXISTS slack_integrations (
    id SERIAL PRIMARY KEY,
    workspace_id VARCHAR(255) REFERENCES workspace_configs(workspace_id),
    team_id VARCHAR(255) NOT NULL,
    team_name VARCHAR(255),
    app_id VARCHAR(255) NOT NULL,
    bot_user_id VARCHAR(255),
    bot_access_token TEXT,
    webhook_url TEXT,
    channels JSONB,
    is_active BOOLEAN DEFAULT true,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Create indexes for better performance
CREATE INDEX IF NOT EXISTS idx_auth_sessions_user_id ON auth_sessions(user_id);
CREATE INDEX IF NOT EXISTS idx_auth_sessions_expires_at ON auth_sessions(expires_at);
CREATE INDEX IF NOT EXISTS idx_audit_logs_user_id ON audit_logs(user_id);
CREATE INDEX IF NOT EXISTS idx_audit_logs_created_at ON audit_logs(created_at);

-- Create update trigger for updated_at columns
CREATE OR REPLACE FUNCTION update_updated_at_column()
RETURNS TRIGGER AS \$\$
BEGIN
    NEW.updated_at = CURRENT_TIMESTAMP;
    RETURN NEW;
END;
\$\$ language 'plpgsql';

-- Apply trigger to tables with updated_at
CREATE TRIGGER update_auth_sessions_updated_at BEFORE UPDATE ON auth_sessions
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_workspace_configs_updated_at BEFORE UPDATE ON workspace_configs
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_project_configs_updated_at BEFORE UPDATE ON project_configs
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_mcp_servers_updated_at BEFORE UPDATE ON mcp_servers
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_slack_integrations_updated_at BEFORE UPDATE ON slack_integrations
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();
EOF

    if [ $? -eq 0 ]; then
        print_success "Tables created successfully in $db_name"
    else
        print_error "Failed to create tables in $db_name"
        return 1
    fi
}

# Function to insert initial configuration
insert_initial_config() {
    local db_name=$1

    print_status "Inserting initial configuration into $db_name..."

    PGPASSWORD=$POSTGRES_PASSWORD psql -h $POSTGRES_HOST -p $POSTGRES_PORT -U $POSTGRES_USER -d $db_name <<EOF
-- Insert workspace configuration
INSERT INTO workspace_configs (workspace_id, workspace_name, workspace_slug, config_data)
VALUES (
    'workspace-prod-8a6f43b9-0c75-4ed6-b820-1a39ef377497',
    'Gray Ghost Data',
    'gray-ghost-data',
    '{
        "key_name": "cursor-config",
        "key_id": "workspace-key-prod-a55a6ebd-8a20-4e13-8df2-d3342c74a6eb",
        "features": ["authentication", "mcp_servers", "slack_integration", "github_integration"]
    }'::jsonb
) ON CONFLICT (workspace_id) DO NOTHING;

-- Insert project configuration
INSERT INTO project_configs (project_id, workspace_id, project_name, project_domain, environment, config_data)
VALUES (
    'project-test-cbf30b45-6865-48f7-a9a5-b1056296b3fa',
    'workspace-prod-8a6f43b9-0c75-4ed6-b820-1a39ef377497',
    'Cursor IDE Development',
    'https://aeolian-sponge-5813.customers.stytch.dev',
    'test',
    '{
        "authentication": {
            "methods": ["magic_links", "oauth", "passkeys"],
            "providers": ["google", "github", "microsoft"],
            "mfa_enabled": true
        },
        "features": ["agents", "automation", "monitoring"]
    }'::jsonb
) ON CONFLICT (project_id) DO NOTHING;

-- Insert Slack integration configuration (use INSERT only, no conflict)
DELETE FROM slack_integrations WHERE workspace_id = 'workspace-prod-8a6f43b9-0c75-4ed6-b820-1a39ef377497';
INSERT INTO slack_integrations (workspace_id, team_id, team_name, app_id, webhook_url, channels, is_active)
VALUES (
    'workspace-prod-8a6f43b9-0c75-4ed6-b820-1a39ef377497',
    'T090MJA31RV',
    'Gray Ghost Data',
    'A09GQ4M79LZ',
    'https://hooks.slack.com/services/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',
    '{
        "notifications": "#dev-notifications",
        "builds": "#ci-cd",
        "reviews": "#code-reviews",
        "security": "#security-alerts"
    }'::jsonb,
    true
);

-- Insert MCP server configurations (delete and re-insert to avoid conflicts)
DELETE FROM mcp_servers WHERE server_name IN ('filesystem', 'git', 'postgres', 'stytch', 'slack', 'github');
INSERT INTO mcp_servers (server_name, server_type, configuration, is_active)
VALUES
    ('filesystem', 'stdio', '{"command": "npx", "args": ["-y", "@modelcontextprotocol/server-filesystem"]}'::jsonb, true),
    ('git', 'stdio', '{"command": "uvx", "args": ["mcp-server-git"]}'::jsonb, true),
    ('postgres', 'stdio', '{"command": "npx", "args": ["-y", "@modelcontextprotocol/server-postgres"]}'::jsonb, true),
    ('stytch', 'stdio', '{"command": "npx", "args": ["-y", "@modelcontextprotocol/server-stytch"]}'::jsonb, true),
    ('slack', 'stdio', '{"command": "npx", "args": ["-y", "@modelcontextprotocol/server-slack"]}'::jsonb, true),
    ('github', 'stdio', '{"command": "npx", "args": ["-y", "@modelcontextprotocol/server-github"]}'::jsonb, true);
EOF

    if [ $? -eq 0 ]; then
        print_success "Initial configuration inserted successfully"
    else
        print_warning "Some configuration may already exist (this is normal)"
    fi
}

# Main execution
main() {
    echo "================================================"
    echo "  CURSOR IDE DATABASE INITIALIZATION"
    echo "================================================"
    echo ""

    # Check PostgreSQL connection
    if ! check_postgres; then
        print_error "Cannot proceed without PostgreSQL connection"
        exit 1
    fi

    # Create databases
    create_database "$DEV_DB" "Development environment"
    create_database "$TEST_DB" "Test environment"
    create_database "$PROD_DB" "Production environment"
    create_database "$PROJECT_DB" "Project-specific data"

    # Create tables in each database
    for db in "$DEV_DB" "$TEST_DB" "$PROD_DB" "$PROJECT_DB"; do
        create_cursor_tables "$db"
        insert_initial_config "$db"
    done

    # Display connection information
    echo ""
    echo "================================================"
    echo "  DATABASE SETUP COMPLETE"
    echo "================================================"
    echo ""
    print_success "All databases have been created and configured"
    echo ""
    echo "Connection strings:"
    echo "  Development: postgresql://$POSTGRES_USER:****@$POSTGRES_HOST:$POSTGRES_PORT/$DEV_DB"
    echo "  Test:        postgresql://$POSTGRES_USER:****@$POSTGRES_HOST:$POSTGRES_PORT/$TEST_DB"
    echo "  Production:  postgresql://$POSTGRES_USER:****@$POSTGRES_HOST:$POSTGRES_PORT/$PROD_DB"
    echo "  Project:     postgresql://$POSTGRES_USER:****@$POSTGRES_HOST:$POSTGRES_PORT/$PROJECT_DB"
    echo ""
    echo "TablePlus configuration:"
    echo "  Host: $POSTGRES_HOST"
    echo "  Port: $POSTGRES_PORT"
    echo "  User: $POSTGRES_USER"
    echo "  Database: $DEV_DB (or any of the above)"
    echo ""
    print_status "You can now start Cursor IDE with: cursor --enable-proposed-api"
}

# Run main function
main "$@"