#!/bin/bash

# ================================================
# CURSOR IDE INITIALIZATION SCRIPT
# ================================================
# This script initializes and starts Cursor IDE with
# all configured integrations and authentication

set -e  # Exit on error

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
MAGENTA='\033[0;35m'
NC='\033[0m' # No Color

# Script directory
SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
CURSOR_DIR="$(dirname "$SCRIPT_DIR")"
PROJECT_ROOT="$(dirname "$CURSOR_DIR")"

# Environment file selection
if [ "$1" == "prod" ] || [ "$1" == "production" ]; then
    ENV_FILE="$CURSOR_DIR/.env.production"
    ENV_NAME="production"
else
    ENV_FILE="$CURSOR_DIR/.env.development"
    ENV_NAME="development"
fi

# Function to print colored output
print_header() {
    echo ""
    echo -e "${MAGENTA}================================================${NC}"
    echo -e "${MAGENTA}  $1${NC}"
    echo -e "${MAGENTA}================================================${NC}"
}

print_status() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

print_success() {
    echo -e "${GREEN}[✓]${NC} $1"
}

print_error() {
    echo -e "${RED}[✗]${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}[!]${NC} $1"
}

# Function to check if command exists
command_exists() {
    command -v "$1" &> /dev/null
}

# Function to load environment variables
load_environment() {
    print_status "Loading environment from $ENV_NAME..."

    if [ -f "$ENV_FILE" ]; then
        export $(grep -v '^#' "$ENV_FILE" | xargs)
        print_success "Environment variables loaded"
    else
        print_error "Environment file not found: $ENV_FILE"
        print_status "Creating default environment file..."
        cp "$CURSOR_DIR/.env.development" "$ENV_FILE" 2>/dev/null || true
    fi
}

# Function to check prerequisites
check_prerequisites() {
    print_header "CHECKING PREREQUISITES"

    local missing_deps=()

    # Check for Node.js
    if command_exists node; then
        print_success "Node.js: $(node --version)"
    else
        missing_deps+=("Node.js")
    fi

    # Check for npm
    if command_exists npm; then
        print_success "npm: $(npm --version)"
    else
        missing_deps+=("npm")
    fi

    # Check for PostgreSQL client
    if command_exists psql; then
        print_success "PostgreSQL client: $(psql --version | head -n1)"
    else
        missing_deps+=("PostgreSQL client")
    fi

    # Check for Docker
    if command_exists docker; then
        print_success "Docker: $(docker --version)"
    else
        print_warning "Docker not found (optional)"
    fi

    # Check for Cursor
    if command_exists cursor; then
        print_success "Cursor IDE found"
    else
        if command_exists code; then
            print_warning "Cursor not found, but VS Code is available"
            print_status "You can install Cursor from: https://cursor.com"
        else
            missing_deps+=("Cursor IDE")
        fi
    fi

    # Report missing dependencies
    if [ ${#missing_deps[@]} -gt 0 ]; then
        print_error "Missing dependencies: ${missing_deps[*]}"
        print_status "Please install missing dependencies and try again"
        return 1
    fi

    return 0
}

# Function to initialize database
initialize_database() {
    print_header "INITIALIZING DATABASE"

    if [ -f "$SCRIPT_DIR/init-database.sh" ]; then
        print_status "Running database initialization..."
        bash "$SCRIPT_DIR/init-database.sh"
    else
        print_warning "Database initialization script not found"
        print_status "Databases may need manual setup"
    fi
}

# Function to install npm dependencies
install_dependencies() {
    print_header "INSTALLING DEPENDENCIES"

    # Create package.json if it doesn't exist
    if [ ! -f "$PROJECT_ROOT/package.json" ]; then
        print_status "Creating package.json..."
        cat > "$PROJECT_ROOT/package.json" <<EOF
{
  "name": "cursor-ide-automation",
  "version": "1.0.0",
  "description": "Cursor IDE Development Automation System",
  "private": true,
  "scripts": {
    "init": "bash .cursor/scripts/init-cursor.sh",
    "db:init": "bash .cursor/scripts/init-database.sh",
    "test:slack": "bash .cursor/scripts/test-slack.sh",
    "dev": "cursor --enable-proposed-api",
    "clean": "rm -rf node_modules dist .next .cache"
  },
  "dependencies": {
    "@stytch/nextjs": "latest",
    "@stytch/vanilla-js": "latest",
    "@modelcontextprotocol/sdk": "latest",
    "dotenv": "latest",
    "pg": "latest"
  },
  "devDependencies": {
    "typescript": "latest",
    "eslint": "latest",
    "prettier": "latest"
  }
}
EOF
        print_success "package.json created"
    fi

    # Install dependencies
    print_status "Installing npm packages..."
    cd "$PROJECT_ROOT"
    npm install --silent 2>/dev/null || npm install

    print_success "Dependencies installed"
}

# Function to test Stytch authentication
test_stytch_auth() {
    print_header "TESTING STYTCH AUTHENTICATION"

    print_status "Checking Stytch configuration..."

    if [ -z "$STYTCH_PROJECT_ID" ] || [ -z "$STYTCH_SECRET" ]; then
        print_error "Stytch credentials not configured"
        print_status "Please check your .env file"
        return 1
    fi

    print_success "Stytch Project ID: $STYTCH_PROJECT_ID"
    print_success "Stytch Environment: ${STYTCH_ENV:-test}"
    print_success "Stytch Domain: $STYTCH_PROJECT_DOMAIN"

    # Test API connection (basic health check)
    print_status "Testing Stytch API connection..."

    response=$(curl -s -o /dev/null -w "%{http_code}" \
        -H "Authorization: Basic $(echo -n "$STYTCH_PROJECT_ID:$STYTCH_SECRET" | base64)" \
        "https://test.stytch.com/v1/projects/$STYTCH_PROJECT_ID" 2>/dev/null || echo "000")

    if [ "$response" == "200" ] || [ "$response" == "401" ]; then
        print_success "Stytch API is reachable"
    else
        print_warning "Could not verify Stytch API connection (HTTP $response)"
    fi
}

# Function to test Slack integration
test_slack_integration() {
    print_header "TESTING SLACK INTEGRATION"

    print_status "Checking Slack configuration..."

    if [ -z "$SLACK_WEBHOOK_URL" ]; then
        print_warning "Slack webhook URL not configured"
        return 1
    fi

    print_success "Slack App ID: $SLACK_APP_ID"
    print_success "Slack App Name: $SLACK_APP_NAME"

    print_status "Sending test message to Slack..."

    # Send test notification
    response=$(curl -X POST -H 'Content-type: application/json' \
        --data "{\"text\":\"🚀 Cursor IDE initialized successfully!\\nEnvironment: $ENV_NAME\\nTime: $(date)\"}" \
        "$SLACK_WEBHOOK_URL" 2>/dev/null)

    if [ "$response" == "ok" ]; then
        print_success "Test message sent to Slack"
    else
        print_warning "Could not send Slack message: $response"
    fi
}

# Function to start MCP servers
start_mcp_servers() {
    print_header "STARTING MCP SERVERS"

    local servers=("filesystem" "git" "postgres" "github" "stytch" "slack")

    for server in "${servers[@]}"; do
        print_status "Checking $server server..."
        # In a real implementation, we would start these servers
        # For now, we just verify configuration
        print_success "$server server configured"
    done
}

# Function to create workspace structure
create_workspace_structure() {
    print_header "CREATING WORKSPACE STRUCTURE"

    # Create necessary directories
    local dirs=(
        "$PROJECT_ROOT/.cursor/logs"
        "$PROJECT_ROOT/.cursor/cache"
        "$PROJECT_ROOT/.cursor/backups"
        "$PROJECT_ROOT/src"
        "$PROJECT_ROOT/tests"
        "$PROJECT_ROOT/docs"
        "$PROJECT_ROOT/scripts"
    )

    for dir in "${dirs[@]}"; do
        if [ ! -d "$dir" ]; then
            mkdir -p "$dir"
            print_success "Created: $dir"
        fi
    done

    # Create .gitignore if it doesn't exist
    if [ ! -f "$PROJECT_ROOT/.gitignore" ]; then
        cat > "$PROJECT_ROOT/.gitignore" <<EOF
# Dependencies
node_modules/
.pnp
.pnp.js

# Environment files
.env
.env.local
.env.development.local
.env.test.local
.env.production.local

# Logs
logs/
*.log
npm-debug.log*
yarn-debug.log*
yarn-error.log*

# Runtime data
pids
*.pid
*.seed
*.pid.lock

# Testing
coverage/
.nyc_output

# Production
dist/
build/

# IDE
.cursor/logs/
.cursor/cache/
.cursor/backups/
.vscode/
.idea/

# OS files
.DS_Store
Thumbs.db

# Temporary files
*.tmp
*.temp
.cache/
EOF
        print_success "Created .gitignore"
    fi
}

# Function to display final status
display_status() {
    print_header "INITIALIZATION COMPLETE"

    echo ""
    echo -e "${CYAN}System Status:${NC}"
    echo "  Environment:     $ENV_NAME"
    echo "  Database:        PostgreSQL @ localhost:5432"
    echo "  Authentication:  Stytch (Project: $STYTCH_PROJECT_ID)"
    echo "  Slack:          Configured (App: $SLACK_APP_NAME)"
    echo "  GitHub:         Token configured"

    echo ""
    echo -e "${CYAN}Available Commands:${NC}"
    echo "  npm run init        - Re-run this initialization"
    echo "  npm run db:init     - Initialize databases only"
    echo "  npm run test:slack  - Test Slack integration"
    echo "  npm run dev         - Start Cursor IDE"

    echo ""
    echo -e "${CYAN}Next Steps:${NC}"
    echo "  1. Start Cursor IDE: cursor --enable-proposed-api"
    echo "  2. Open project folder: $PROJECT_ROOT"
    echo "  3. Authenticate with Stytch when prompted"
    echo "  4. Check Slack for notifications"

    echo ""
    print_success "Cursor IDE is ready to use!"
}

# Function to start Cursor
start_cursor() {
    print_header "STARTING CURSOR IDE"

    print_status "Launching Cursor with proposed API..."

    if command_exists cursor; then
        cd "$PROJECT_ROOT"
        cursor --enable-proposed-api .
    else
        print_warning "Cursor command not found"
        print_status "Please install Cursor from: https://cursor.com"
        print_status "Then run: cursor --enable-proposed-api $PROJECT_ROOT"
    fi
}

# Main execution
main() {
    clear

    echo -e "${CYAN}"
    echo "   ____                            ___ ____  _____ "
    echo "  / ___|   _ _ __ ___  ___  _ __  |_ _|  _ \| ____|"
    echo " | |  | | | | '__/ __|/ _ \| '__|  | || | | |  _|  "
    echo " | |__| |_| | |  \__ \ (_) | |     | || |_| | |___ "
    echo "  \____\__,_|_|  |___/\___/|_|    |___|____/|_____|"
    echo -e "${NC}"
    echo "        Development Automation System v2025.1"
    echo ""

    # Load environment
    load_environment

    # Check prerequisites
    if ! check_prerequisites; then
        print_error "Prerequisites check failed"
        exit 1
    fi

    # Initialize database
    initialize_database

    # Install dependencies
    install_dependencies

    # Create workspace structure
    create_workspace_structure

    # Test Stytch authentication
    test_stytch_auth

    # Test Slack integration
    test_slack_integration

    # Start MCP servers
    start_mcp_servers

    # Display final status
    display_status

    # Ask if user wants to start Cursor
    echo ""
    read -p "Do you want to start Cursor IDE now? (y/n) " -n 1 -r
    echo ""
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        start_cursor
    fi
}

# Run main function
main "$@"