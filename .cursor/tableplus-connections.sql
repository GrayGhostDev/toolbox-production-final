-- TablePlus Connection Settings for Cursor IDE
--
-- IMPORTANT: SSL Mode Settings
-- ================================
-- For Docker PostgreSQL containers without SSL certificates:
-- Use sslmode=disable or sslmode=allow
--
-- For production with SSL:
-- Use sslmode=require or sslmode=verify-full

-- Connection 1: Claude PostgreSQL (Docker - No SSL)
-- Host: localhost or 127.0.0.1
-- Port: 5432
-- Database: postgres
-- User: postgres
-- Password: (your password)
-- SSL Mode: disable
-- Connection String: postgresql://postgres:password@localhost:5432/postgres?sslmode=disable

-- Connection 2: Gray Ghost PostgreSQL (Docker - No SSL)
-- Host: localhost or 127.0.0.1
-- Port: 5433
-- Database: postgres
-- User: postgres
-- Password: (your password)
-- SSL Mode: disable
-- Connection String: postgresql://postgres:password@localhost:5433/postgres?sslmode=disable

-- Connection 3: Cursor Development Database
-- Host: localhost or 127.0.0.1
-- Port: 5432
-- Database: cursor_development
-- User: postgres
-- Password: (your password)
-- SSL Mode: disable
-- Connection String: postgresql://postgres:password@localhost:5432/cursor_development?sslmode=disable

-- Test connection command from terminal:
-- psql "postgresql://postgres:password@localhost:5432/postgres?sslmode=disable"