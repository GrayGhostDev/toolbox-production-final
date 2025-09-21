#!/bin/bash

# ================================================
# TOOLBOX DATABASE INITIALIZATION SCRIPT
# ================================================

set -e

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

# Configuration
POSTGRES_USER="${POSTGRES_USER:-claude}"
POSTGRES_PASSWORD="${POSTGRES_PASSWORD:-changeme}"
POSTGRES_HOST="${POSTGRES_HOST:-localhost}"
POSTGRES_PORT="${POSTGRES_PORT:-5432}"

# Toolbox Database names
TOOLBOX_DEV_DB="toolbox_development"
TOOLBOX_TEST_DB="toolbox_test"
TOOLBOX_PROD_DB="toolbox_production"

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

# Check PostgreSQL connection
check_postgres() {
    print_status "Checking PostgreSQL connection..."

    if PGPASSWORD=$POSTGRES_PASSWORD psql -h $POSTGRES_HOST -p $POSTGRES_PORT -U $POSTGRES_USER -lqt 2>/dev/null; then
        print_success "PostgreSQL is running and accessible"
        return 0
    else
        print_error "Cannot connect to PostgreSQL"
        return 1
    fi
}

# Create database if it doesn't exist
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

    # Grant privileges
    PGPASSWORD=$POSTGRES_PASSWORD psql -h $POSTGRES_HOST -p $POSTGRES_PORT -U $POSTGRES_USER -c "GRANT ALL PRIVILEGES ON DATABASE $db_name TO $POSTGRES_USER;" 2>/dev/null || true
}

# Create tables for toolbox application
create_toolbox_tables() {
    local db_name=$1

    print_status "Creating tables in $db_name..."

    PGPASSWORD=$POSTGRES_PASSWORD psql -h $POSTGRES_HOST -p $POSTGRES_PORT -U $POSTGRES_USER -d $db_name <<EOF
-- Users table (integrated with Stytch)
CREATE TABLE IF NOT EXISTS users (
    id SERIAL PRIMARY KEY,
    stytch_user_id VARCHAR(255) UNIQUE NOT NULL,
    email VARCHAR(255) UNIQUE NOT NULL,
    name VARCHAR(255),
    avatar_url TEXT,
    role VARCHAR(50) DEFAULT 'user',
    organization_id VARCHAR(255),
    metadata JSONB DEFAULT '{}',
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    last_login_at TIMESTAMP
);

-- Organizations table
CREATE TABLE IF NOT EXISTS organizations (
    id SERIAL PRIMARY KEY,
    stytch_org_id VARCHAR(255) UNIQUE NOT NULL,
    name VARCHAR(255) NOT NULL,
    slug VARCHAR(255) UNIQUE NOT NULL,
    domain VARCHAR(255),
    settings JSONB DEFAULT '{}',
    subscription_tier VARCHAR(50) DEFAULT 'free',
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Projects table
CREATE TABLE IF NOT EXISTS projects (
    id SERIAL PRIMARY KEY,
    project_id VARCHAR(255) UNIQUE NOT NULL,
    organization_id INTEGER REFERENCES organizations(id),
    name VARCHAR(255) NOT NULL,
    description TEXT,
    status VARCHAR(50) DEFAULT 'active',
    settings JSONB DEFAULT '{}',
    created_by INTEGER REFERENCES users(id),
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Tasks table
CREATE TABLE IF NOT EXISTS tasks (
    id SERIAL PRIMARY KEY,
    task_id VARCHAR(255) UNIQUE NOT NULL,
    project_id INTEGER REFERENCES projects(id),
    assigned_to INTEGER REFERENCES users(id),
    title VARCHAR(500) NOT NULL,
    description TEXT,
    status VARCHAR(50) DEFAULT 'pending',
    priority VARCHAR(20) DEFAULT 'medium',
    due_date TIMESTAMP,
    completed_at TIMESTAMP,
    metadata JSONB DEFAULT '{}',
    created_by INTEGER REFERENCES users(id),
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Automations table
CREATE TABLE IF NOT EXISTS automations (
    id SERIAL PRIMARY KEY,
    automation_id VARCHAR(255) UNIQUE NOT NULL,
    project_id INTEGER REFERENCES projects(id),
    name VARCHAR(255) NOT NULL,
    trigger_type VARCHAR(50) NOT NULL,
    trigger_config JSONB NOT NULL,
    actions JSONB NOT NULL,
    is_enabled BOOLEAN DEFAULT true,
    last_run_at TIMESTAMP,
    run_count INTEGER DEFAULT 0,
    created_by INTEGER REFERENCES users(id),
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Integrations table
CREATE TABLE IF NOT EXISTS integrations (
    id SERIAL PRIMARY KEY,
    organization_id INTEGER REFERENCES organizations(id),
    service_name VARCHAR(100) NOT NULL,
    service_type VARCHAR(50) NOT NULL,
    credentials JSONB,
    settings JSONB DEFAULT '{}',
    is_active BOOLEAN DEFAULT true,
    last_sync_at TIMESTAMP,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    UNIQUE(organization_id, service_name)
);

-- Activity logs table
CREATE TABLE IF NOT EXISTS activity_logs (
    id SERIAL PRIMARY KEY,
    user_id INTEGER REFERENCES users(id),
    organization_id INTEGER REFERENCES organizations(id),
    action VARCHAR(255) NOT NULL,
    resource_type VARCHAR(100),
    resource_id VARCHAR(255),
    details JSONB,
    ip_address INET,
    user_agent TEXT,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Reports table
CREATE TABLE IF NOT EXISTS reports (
    id SERIAL PRIMARY KEY,
    report_id VARCHAR(255) UNIQUE NOT NULL,
    organization_id INTEGER REFERENCES organizations(id),
    name VARCHAR(255) NOT NULL,
    type VARCHAR(50) NOT NULL,
    parameters JSONB DEFAULT '{}',
    data JSONB,
    generated_by INTEGER REFERENCES users(id),
    generated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- API keys table
CREATE TABLE IF NOT EXISTS api_keys (
    id SERIAL PRIMARY KEY,
    key_id VARCHAR(255) UNIQUE NOT NULL,
    organization_id INTEGER REFERENCES organizations(id),
    name VARCHAR(255) NOT NULL,
    key_hash VARCHAR(255) NOT NULL,
    permissions JSONB DEFAULT '{}',
    last_used_at TIMESTAMP,
    expires_at TIMESTAMP,
    is_active BOOLEAN DEFAULT true,
    created_by INTEGER REFERENCES users(id),
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Create indexes for performance
CREATE INDEX IF NOT EXISTS idx_users_email ON users(email);
CREATE INDEX IF NOT EXISTS idx_users_stytch_id ON users(stytch_user_id);
CREATE INDEX IF NOT EXISTS idx_projects_org ON projects(organization_id);
CREATE INDEX IF NOT EXISTS idx_tasks_project ON tasks(project_id);
CREATE INDEX IF NOT EXISTS idx_tasks_assigned ON tasks(assigned_to);
CREATE INDEX IF NOT EXISTS idx_activity_logs_user ON activity_logs(user_id);
CREATE INDEX IF NOT EXISTS idx_activity_logs_created ON activity_logs(created_at);

-- Create update trigger for updated_at columns
CREATE OR REPLACE FUNCTION update_updated_at_column()
RETURNS TRIGGER AS \$\$
BEGIN
    NEW.updated_at = CURRENT_TIMESTAMP;
    RETURN NEW;
END;
\$\$ language 'plpgsql';

-- Apply trigger to tables with updated_at
CREATE TRIGGER update_users_updated_at BEFORE UPDATE ON users
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_organizations_updated_at BEFORE UPDATE ON organizations
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_projects_updated_at BEFORE UPDATE ON projects
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_tasks_updated_at BEFORE UPDATE ON tasks
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_automations_updated_at BEFORE UPDATE ON automations
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_integrations_updated_at BEFORE UPDATE ON integrations
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();
EOF

    if [ $? -eq 0 ]; then
        print_success "Tables created successfully in $db_name"
    else
        print_error "Failed to create tables in $db_name"
        return 1
    fi
}

# Insert initial data
insert_initial_data() {
    local db_name=$1

    print_status "Inserting initial data into $db_name..."

    PGPASSWORD=$POSTGRES_PASSWORD psql -h $POSTGRES_HOST -p $POSTGRES_PORT -U $POSTGRES_USER -d $db_name <<EOF
-- Insert default organization
INSERT INTO organizations (stytch_org_id, name, slug, domain, settings, subscription_tier)
VALUES (
    'organization-prod-8a6f43b9-0c75-4ed6-b820-1a39ef377497',
    'Gray Ghost Data',
    'gray-ghost-data',
    'grayghostdata.com',
    '{"features": ["unlimited_projects", "advanced_analytics", "priority_support"]}',
    'enterprise'
) ON CONFLICT (stytch_org_id) DO NOTHING;

-- Insert default integrations
INSERT INTO integrations (organization_id, service_name, service_type, settings, is_active)
VALUES
    (1, 'github', 'vcs', '{"org": "gray-ghost-data", "repos": ["toolbox-production-final"]}', true),
    (1, 'slack', 'communication', '{"workspace": "gray-ghost-data", "channels": ["general", "dev"]}', true),
    (1, 'postgresql', 'database', '{"host": "localhost", "port": 5432}', true)
ON CONFLICT (organization_id, service_name) DO NOTHING;
EOF

    print_success "Initial data inserted successfully"
}

# Main execution
main() {
    echo "================================================"
    echo "  TOOLBOX DATABASE INITIALIZATION"
    echo "================================================"
    echo ""

    # Check PostgreSQL connection
    if ! check_postgres; then
        print_error "Cannot proceed without PostgreSQL connection"
        exit 1
    fi

    # Create databases
    create_database "$TOOLBOX_DEV_DB" "Toolbox Development"
    create_database "$TOOLBOX_TEST_DB" "Toolbox Testing"
    create_database "$TOOLBOX_PROD_DB" "Toolbox Production"

    # Create tables and insert data
    for db in "$TOOLBOX_DEV_DB" "$TOOLBOX_TEST_DB" "$TOOLBOX_PROD_DB"; do
        create_toolbox_tables "$db"
        insert_initial_data "$db"
    done

    # Display connection information
    echo ""
    echo "================================================"
    echo "  TOOLBOX DATABASE SETUP COMPLETE"
    echo "================================================"
    echo ""
    print_success "All Toolbox databases have been created and configured"
    echo ""
    echo "Connection strings:"
    echo "  Development: postgresql://$POSTGRES_USER:****@$POSTGRES_HOST:$POSTGRES_PORT/$TOOLBOX_DEV_DB?sslmode=disable"
    echo "  Test:        postgresql://$POSTGRES_USER:****@$POSTGRES_HOST:$POSTGRES_PORT/$TOOLBOX_TEST_DB?sslmode=disable"
    echo "  Production:  postgresql://$POSTGRES_USER:****@$POSTGRES_HOST:$POSTGRES_PORT/$TOOLBOX_PROD_DB?sslmode=disable"
    echo ""
    echo "TablePlus configuration:"
    echo "  Host: $POSTGRES_HOST"
    echo "  Port: $POSTGRES_PORT"
    echo "  User: $POSTGRES_USER"
    echo "  Database: $TOOLBOX_DEV_DB"
    echo "  SSL Mode: Disable"
    echo ""
}

# Run main function
main "$@"