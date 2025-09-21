# Fix TablePlus SSL Connection Error

## Problem
TablePlus is trying to connect with SSL required, but Docker PostgreSQL containers don't have SSL configured.

## Solution

### In TablePlus GUI:

1. **Open Connection Settings**
   - Click on the connection that's failing
   - Or create a new connection

2. **Configure Connection**:
   ```
   Name: Cursor Development (Docker)
   Host: 127.0.0.1 (or localhost)
   Port: 5432
   User: postgres
   Password: [your password]
   Database: postgres (or cursor_development)
   ```

3. **IMPORTANT - Disable SSL**:
   - Look for "SSL Mode" dropdown
   - Change from "Require" to **"Disable"** or **"Allow"**
   - Or in Advanced tab, set: `sslmode=disable`

4. **Alternative - Use Connection URL**:
   - In TablePlus, you can use "Import from URL"
   - Use this format:
   ```
   postgresql://postgres:yourpassword@localhost:5432/postgres?sslmode=disable
   ```

## Available Connections

### 1. Claude PostgreSQL (Main Docker)
- **Host**: localhost
- **Port**: 5432
- **Database**: postgres
- **User**: postgres
- **SSL Mode**: disable

### 2. Gray Ghost PostgreSQL
- **Host**: localhost
- **Port**: 5433
- **Database**: postgres
- **User**: postgres
- **SSL Mode**: disable

### 3. Cursor Development DB
- **Host**: localhost
- **Port**: 5432
- **Database**: cursor_development
- **User**: postgres
- **SSL Mode**: disable

## SSH Tunnel Option (Alternative)

If you prefer using SSH tunnel with TablePlus:

1. **Connection Tab**:
   ```
   Host: 127.0.0.1
   Port: 5432
   Database: postgres
   User: postgres
   Password: [your password]
   SSL Mode: disable
   ```

2. **SSH Tab**:
   ```
   Use SSH: ✓ Enabled
   Server: localhost
   Port: 22
   User: grayghostdata
   Auth: SSH Key
   Private Key: ~/.ssh/id_ed25519
   ```

## Testing Connection

From terminal:
```bash
# Test without SSL
psql "postgresql://postgres@localhost:5432/postgres?sslmode=disable"

# Or with PGPASSWORD
PGPASSWORD=yourpassword psql -h localhost -p 5432 -U postgres -d postgres

# For Gray Ghost PostgreSQL (port 5433)
psql "postgresql://postgres@localhost:5433/postgres?sslmode=disable"
```

## Common SSL Mode Options

- **disable**: Never use SSL (for local Docker)
- **allow**: Try non-SSL first, then SSL
- **prefer**: Try SSL first, then non-SSL
- **require**: Always use SSL (fails if not available)
- **verify-ca**: SSL + verify certificate
- **verify-full**: SSL + verify certificate + hostname

For local Docker development, use **"disable"** or **"allow"**.