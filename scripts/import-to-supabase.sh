#!/bin/bash

# ================================================
# SUPABASE SCHEMA IMPORT SCRIPT
# ================================================

set -e

# Colors
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m'

echo -e "${GREEN}================================================${NC}"
echo -e "${GREEN}  SUPABASE SCHEMA IMPORT${NC}"
echo -e "${GREEN}================================================${NC}"
echo ""

# Load environment variables
if [ -f .env.local ]; then
    export $(grep -v '^#' .env.local | xargs)
fi

# Check if required variables are set
if [ -z "$SUPABASE_DB_URL" ]; then
    echo -e "${RED}Error: SUPABASE_DB_URL not found in .env.local${NC}"
    exit 1
fi

echo -e "${YELLOW}This script will import the following to Supabase Cloud:${NC}"
echo "1. Database schema (tables, functions, triggers)"
echo "2. Row Level Security policies"
echo "3. Production security configuration"
echo ""
echo -e "${YELLOW}WARNING: This will modify your Supabase database!${NC}"
read -p "Do you want to continue? (y/N): " -n 1 -r
echo ""

if [[ ! $REPLY =~ ^[Yy]$ ]]; then
    echo "Import cancelled."
    exit 0
fi

# Function to run SQL file
run_sql() {
    local file=$1
    local description=$2

    echo -e "\n${GREEN}→ ${description}${NC}"

    if [ -f "$file" ]; then
        # Use psql to connect to Supabase and run the SQL
        PGPASSWORD="$SUPABASE_DB_PASSWORD" psql "$SUPABASE_DB_URL" -f "$file" 2>&1 | grep -v "NOTICE:" || {
            echo -e "${RED}Failed to run: $file${NC}"
            return 1
        }
        echo -e "${GREEN}✓ Complete${NC}"
    else
        echo -e "${YELLOW}File not found: $file${NC}"
        return 1
    fi
}

# Import schema files in order
echo -e "\n${GREEN}Starting schema import...${NC}"

# 1. Initial schema
run_sql "supabase/migrations/001_initial_schema.sql" "Creating tables and functions"

# 2. RLS policies
run_sql "supabase/migrations/002_row_level_security.sql" "Configuring Row Level Security"

# 3. Production security
run_sql "supabase/migrations/003_production_security.sql" "Setting up production security"

echo -e "\n${GREEN}================================================${NC}"
echo -e "${GREEN}  IMPORT COMPLETE!${NC}"
echo -e "${GREEN}================================================${NC}"
echo ""
echo "Next steps:"
echo "1. Go to Supabase Dashboard to verify tables"
echo "2. Check RLS policies are enabled"
echo "3. Test authentication flow"
echo ""
echo -e "${GREEN}Supabase Dashboard:${NC} https://supabase.com/dashboard/project/jlesbkscprldariqcbvt"