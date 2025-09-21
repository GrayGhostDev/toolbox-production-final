#!/bin/bash

# ================================================
# MCP SERVERS VERIFICATION SCRIPT
# ================================================

set -e

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
NC='\033[0m'

# Script directory
SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
CURSOR_DIR="$(dirname "$SCRIPT_DIR")"

echo -e "${CYAN}================================================${NC}"
echo -e "${CYAN}  MCP SERVERS VERIFICATION${NC}"
echo -e "${CYAN}================================================${NC}"
echo ""

# Function to check if npm package exists
check_npm_package() {
    local package=$1
    if npm list "$package" 2>/dev/null | grep -q "$package"; then
        echo -e "${GREEN}✓${NC} $package installed"
        return 0
    else
        echo -e "${YELLOW}⚠${NC} $package not installed - installing..."
        npm install "$package" 2>/dev/null || echo -e "${RED}✗${NC} Failed to install $package"
        return 1
    fi
}

# Function to check MCP server configuration
check_mcp_config() {
    local server_name=$1
    local config_file="$CURSOR_DIR/mcp.json"

    if [ -f "$config_file" ]; then
        if grep -q "\"$server_name\"" "$config_file"; then
            echo -e "${GREEN}✓${NC} $server_name configured in mcp.json"
            return 0
        else
            echo -e "${RED}✗${NC} $server_name not configured in mcp.json"
            return 1
        fi
    else
        echo -e "${RED}✗${NC} mcp.json not found"
        return 1
    fi
}

# Function to test server availability
test_server() {
    local server_name=$1
    local test_command=$2

    echo -e "${BLUE}Testing $server_name...${NC}"
    if eval "$test_command" 2>/dev/null; then
        echo -e "${GREEN}✓${NC} $server_name is operational"
        return 0
    else
        echo -e "${YELLOW}⚠${NC} $server_name test skipped or not available"
        return 1
    fi
}

echo -e "${BLUE}1. Checking MCP Server Packages${NC}"
echo "--------------------------------"

# Check required MCP server packages
servers=(
    "@modelcontextprotocol/server-filesystem"
    "@modelcontextprotocol/server-postgres"
    "@modelcontextprotocol/server-github"
    "@modelcontextprotocol/server-memory"
    "@modelcontextprotocol/server-sequential-thinking"
    "@modelcontextprotocol/server-slack"
)

installed_count=0
total_count=${#servers[@]}

for server in "${servers[@]}"; do
    if check_npm_package "$server"; then
        ((installed_count++))
    fi
done

echo ""
echo -e "Package Status: ${installed_count}/${total_count} installed"
echo ""

echo -e "${BLUE}2. Checking MCP Configuration${NC}"
echo "--------------------------------"

# Check configuration for each server
config_servers=(
    "filesystem"
    "git"
    "postgres"
    "github"
    "memory"
    "sequential-thinking"
    "stytch"
    "slack"
    "docker"
    "kubernetes"
    "puppeteer"
)

configured_count=0
total_config=${#config_servers[@]}

for server in "${config_servers[@]}"; do
    if check_mcp_config "$server"; then
        ((configured_count++))
    fi
done

echo ""
echo -e "Configuration Status: ${configured_count}/${total_config} configured"
echo ""

echo -e "${BLUE}3. Testing Server Connectivity${NC}"
echo "--------------------------------"

# Test filesystem access
test_server "Filesystem" "ls -la $HOME/.cursor 2>/dev/null | head -5"

# Test Git
test_server "Git" "git --version"

# Test PostgreSQL
test_server "PostgreSQL" "PGPASSWORD=changeme psql -h localhost -p 5432 -U claude -c '\\l' 2>/dev/null | grep toolbox_development"

# Test Docker
test_server "Docker" "docker --version"

# Test Node.js (for MCP servers)
test_server "Node.js" "node --version"

echo ""
echo -e "${BLUE}4. Checking Environment Variables${NC}"
echo "--------------------------------"

# Check for required environment variables
env_vars=(
    "STYTCH_PROJECT_ID"
    "STYTCH_SECRET"
    "GITHUB_TOKEN"
    "SLACK_WEBHOOK_URL"
    "DATABASE_URL"
)

# Load environment file
if [ -f "$CURSOR_DIR/.env.development" ]; then
    export $(grep -v '^#' "$CURSOR_DIR/.env.development" | xargs) 2>/dev/null
fi

env_configured=0
env_total=${#env_vars[@]}

for var in "${env_vars[@]}"; do
    if [ ! -z "${!var}" ]; then
        echo -e "${GREEN}✓${NC} $var is set"
        ((env_configured++))
    else
        echo -e "${RED}✗${NC} $var is not set"
    fi
done

echo ""
echo -e "Environment Status: ${env_configured}/${env_total} configured"
echo ""

echo -e "${BLUE}5. MCP Server Health Summary${NC}"
echo "--------------------------------"

# Calculate overall health
total_checks=$((total_count + total_config + env_total))
successful_checks=$((installed_count + configured_count + env_configured))
health_percentage=$((successful_checks * 100 / total_checks))

if [ $health_percentage -ge 80 ]; then
    echo -e "${GREEN}✓ MCP Servers Health: ${health_percentage}% - GOOD${NC}"
elif [ $health_percentage -ge 60 ]; then
    echo -e "${YELLOW}⚠ MCP Servers Health: ${health_percentage}% - FAIR${NC}"
else
    echo -e "${RED}✗ MCP Servers Health: ${health_percentage}% - NEEDS ATTENTION${NC}"
fi

echo ""
echo -e "${CYAN}Recommendations:${NC}"

if [ $installed_count -lt $total_count ]; then
    echo "- Install missing MCP server packages using npm"
fi

if [ $configured_count -lt $total_config ]; then
    echo "- Review and update mcp.json configuration"
fi

if [ $env_configured -lt $env_total ]; then
    echo "- Set missing environment variables in .env files"
fi

if [ $health_percentage -ge 80 ]; then
    echo -e "${GREEN}✓ MCP servers are ready for use with Cursor IDE${NC}"
fi

echo ""
echo -e "${CYAN}To start Cursor with MCP servers:${NC}"
echo "  cursor --enable-proposed-api"
echo ""