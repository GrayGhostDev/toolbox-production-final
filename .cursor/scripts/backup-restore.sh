#!/bin/bash

# ================================================
# BACKUP AND RESTORE SCRIPT FOR CURSOR IDE
# ================================================

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
NC='\033[0m'

# Configuration
SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
CURSOR_DIR="$(dirname "$SCRIPT_DIR")"
BACKUP_DIR="$CURSOR_DIR/backups"
TIMESTAMP=$(date +%Y%m%d_%H%M%S)

# Database configuration
DB_HOST="${POSTGRES_HOST:-localhost}"
DB_PORT="${POSTGRES_PORT:-5432}"
DB_USER="${POSTGRES_USER:-claude}"
DB_PASSWORD="${POSTGRES_PASSWORD:-changeme}"

# Function to print colored output
print_header() {
    echo -e "\n${CYAN}================================================${NC}"
    echo -e "${CYAN}  $1${NC}"
    echo -e "${CYAN}================================================${NC}\n"
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

# Function to show usage
usage() {
    echo "Usage: $0 [backup|restore|list|clean] [options]"
    echo ""
    echo "Commands:"
    echo "  backup    Create a backup of all Cursor IDE data"
    echo "  restore   Restore from a backup"
    echo "  list      List available backups"
    echo "  clean     Remove old backups (keep last 7 days)"
    echo ""
    echo "Options:"
    echo "  --db-only        Only backup/restore databases"
    echo "  --config-only    Only backup/restore configuration files"
    echo "  --file <path>    Specify backup file for restore"
    echo ""
    exit 1
}

# Function to create backup directory
ensure_backup_dir() {
    if [ ! -d "$BACKUP_DIR" ]; then
        mkdir -p "$BACKUP_DIR"
        print_success "Created backup directory: $BACKUP_DIR"
    fi
}

# Function to backup databases
backup_databases() {
    print_header "BACKING UP DATABASES"

    local db_backup_dir="$BACKUP_DIR/db_$TIMESTAMP"
    mkdir -p "$db_backup_dir"

    databases=("cursor_development" "cursor_test" "cursor_production" "cursor_project")

    for db in "${databases[@]}"; do
        print_status "Backing up database: $db"
        PGPASSWORD="$DB_PASSWORD" pg_dump \
            -h "$DB_HOST" \
            -p "$DB_PORT" \
            -U "$DB_USER" \
            -d "$db" \
            -f "$db_backup_dir/${db}.sql" 2>/dev/null

        if [ $? -eq 0 ]; then
            print_success "Backed up: $db"
        else
            print_warning "Failed to backup: $db"
        fi
    done

    # Compress database backups
    print_status "Compressing database backups..."
    tar -czf "$BACKUP_DIR/db_backup_$TIMESTAMP.tar.gz" -C "$BACKUP_DIR" "db_$TIMESTAMP"
    rm -rf "$db_backup_dir"

    print_success "Database backup completed: db_backup_$TIMESTAMP.tar.gz"
}

# Function to backup configuration files
backup_configs() {
    print_header "BACKING UP CONFIGURATION FILES"

    local config_backup_dir="$BACKUP_DIR/config_$TIMESTAMP"
    mkdir -p "$config_backup_dir"

    # Files to backup
    config_files=(
        "$CURSOR_DIR/mcp.json"
        "$CURSOR_DIR/settings.json"
        "$CURSOR_DIR/rules.json"
        "$CURSOR_DIR/workspace-config.json"
        "$CURSOR_DIR/tableplus-config.json"
        "$CURSOR_DIR/.env.development"
        "$CURSOR_DIR/.env.production"
        "$HOME/.cursorrules"
        "$HOME/automation.config.js"
        "$HOME/.ssh/config"
    )

    for file in "${config_files[@]}"; do
        if [ -f "$file" ]; then
            filename=$(basename "$file")
            cp "$file" "$config_backup_dir/$filename"
            print_success "Backed up: $filename"
        else
            print_warning "File not found: $file"
        fi
    done

    # Compress configuration backup
    print_status "Compressing configuration backup..."
    tar -czf "$BACKUP_DIR/config_backup_$TIMESTAMP.tar.gz" -C "$BACKUP_DIR" "config_$TIMESTAMP"
    rm -rf "$config_backup_dir"

    print_success "Configuration backup completed: config_backup_$TIMESTAMP.tar.gz"
}

# Function to create full backup
backup_full() {
    print_header "CREATING FULL BACKUP"

    ensure_backup_dir
    backup_databases
    backup_configs

    # Create manifest file
    cat > "$BACKUP_DIR/backup_manifest_$TIMESTAMP.json" <<EOF
{
    "timestamp": "$TIMESTAMP",
    "date": "$(date)",
    "type": "full",
    "database_backup": "db_backup_$TIMESTAMP.tar.gz",
    "config_backup": "config_backup_$TIMESTAMP.tar.gz",
    "cursor_version": "$(cursor --version 2>/dev/null || echo 'unknown')",
    "postgres_version": "$(psql --version 2>/dev/null | head -1 || echo 'unknown')"
}
EOF

    print_success "Full backup completed successfully!"
    echo ""
    echo "Backup location: $BACKUP_DIR"
    echo "Manifest: backup_manifest_$TIMESTAMP.json"
}

# Function to restore databases
restore_databases() {
    local backup_file=$1

    print_header "RESTORING DATABASES"

    # Extract database backup
    local temp_dir="/tmp/cursor_restore_$$"
    mkdir -p "$temp_dir"

    print_status "Extracting database backup..."
    tar -xzf "$backup_file" -C "$temp_dir"

    # Find the database directory
    local db_dir=$(find "$temp_dir" -type d -name "db_*" | head -1)

    if [ -z "$db_dir" ]; then
        print_error "No database backup found in archive"
        rm -rf "$temp_dir"
        return 1
    fi

    # Restore each database
    for sql_file in "$db_dir"/*.sql; do
        if [ -f "$sql_file" ]; then
            db_name=$(basename "$sql_file" .sql)
            print_status "Restoring database: $db_name"

            # Drop and recreate database
            PGPASSWORD="$DB_PASSWORD" psql \
                -h "$DB_HOST" \
                -p "$DB_PORT" \
                -U "$DB_USER" \
                -d claude_system \
                -c "DROP DATABASE IF EXISTS $db_name; CREATE DATABASE $db_name;" 2>/dev/null

            # Restore from backup
            PGPASSWORD="$DB_PASSWORD" psql \
                -h "$DB_HOST" \
                -p "$DB_PORT" \
                -U "$DB_USER" \
                -d "$db_name" \
                -f "$sql_file" 2>/dev/null

            if [ $? -eq 0 ]; then
                print_success "Restored: $db_name"
            else
                print_warning "Failed to restore: $db_name"
            fi
        fi
    done

    rm -rf "$temp_dir"
    print_success "Database restoration completed"
}

# Function to restore configuration files
restore_configs() {
    local backup_file=$1

    print_header "RESTORING CONFIGURATION FILES"

    # Extract configuration backup
    local temp_dir="/tmp/cursor_restore_config_$$"
    mkdir -p "$temp_dir"

    print_status "Extracting configuration backup..."
    tar -xzf "$backup_file" -C "$temp_dir"

    # Find the config directory
    local config_dir=$(find "$temp_dir" -type d -name "config_*" | head -1)

    if [ -z "$config_dir" ]; then
        print_error "No configuration backup found in archive"
        rm -rf "$temp_dir"
        return 1
    fi

    # Create backup of current configs
    print_status "Backing up current configuration..."
    local current_backup="$BACKUP_DIR/pre_restore_backup_$(date +%Y%m%d_%H%M%S)"
    mkdir -p "$current_backup"

    # Restore configuration files
    for file in "$config_dir"/*; do
        if [ -f "$file" ]; then
            filename=$(basename "$file")

            # Determine destination based on filename
            case "$filename" in
                .env.*)
                    dest="$CURSOR_DIR/$filename"
                    ;;
                mcp.json|settings.json|rules.json|workspace-config.json|tableplus-config.json)
                    dest="$CURSOR_DIR/$filename"
                    ;;
                .cursorrules|automation.config.js)
                    dest="$HOME/$filename"
                    ;;
                config)
                    dest="$HOME/.ssh/config"
                    ;;
                *)
                    print_warning "Unknown file: $filename"
                    continue
                    ;;
            esac

            # Backup current file if it exists
            if [ -f "$dest" ]; then
                cp "$dest" "$current_backup/$(basename $dest).bak"
            fi

            # Restore file
            cp "$file" "$dest"
            print_success "Restored: $filename"
        fi
    done

    rm -rf "$temp_dir"
    print_success "Configuration restoration completed"
    print_status "Previous configuration backed up to: $current_backup"
}

# Function to list backups
list_backups() {
    print_header "AVAILABLE BACKUPS"

    if [ ! -d "$BACKUP_DIR" ]; then
        print_warning "No backup directory found"
        return
    fi

    # List database backups
    echo -e "${CYAN}Database Backups:${NC}"
    for backup in "$BACKUP_DIR"/db_backup_*.tar.gz; do
        if [ -f "$backup" ]; then
            size=$(ls -lh "$backup" | awk '{print $5}')
            date=$(stat -f "%Sm" -t "%Y-%m-%d %H:%M" "$backup" 2>/dev/null || stat -c "%y" "$backup" 2>/dev/null | cut -d' ' -f1-2)
            echo "  - $(basename $backup) [$size] - $date"
        fi
    done

    echo ""

    # List configuration backups
    echo -e "${CYAN}Configuration Backups:${NC}"
    for backup in "$BACKUP_DIR"/config_backup_*.tar.gz; do
        if [ -f "$backup" ]; then
            size=$(ls -lh "$backup" | awk '{print $5}')
            date=$(stat -f "%Sm" -t "%Y-%m-%d %H:%M" "$backup" 2>/dev/null || stat -c "%y" "$backup" 2>/dev/null | cut -d' ' -f1-2)
            echo "  - $(basename $backup) [$size] - $date"
        fi
    done

    echo ""

    # Show total size
    if [ -d "$BACKUP_DIR" ]; then
        total_size=$(du -sh "$BACKUP_DIR" | awk '{print $1}')
        echo -e "${CYAN}Total backup size: $total_size${NC}"
    fi
}

# Function to clean old backups
clean_backups() {
    print_header "CLEANING OLD BACKUPS"

    if [ ! -d "$BACKUP_DIR" ]; then
        print_warning "No backup directory found"
        return
    fi

    # Keep backups from last 7 days
    print_status "Removing backups older than 7 days..."

    find "$BACKUP_DIR" -name "*.tar.gz" -type f -mtime +7 -delete
    find "$BACKUP_DIR" -name "*.json" -type f -mtime +7 -delete

    print_success "Cleanup completed"

    # Show remaining backups
    list_backups
}

# Main script logic
main() {
    case "$1" in
        backup)
            if [ "$2" == "--db-only" ]; then
                ensure_backup_dir
                backup_databases
            elif [ "$2" == "--config-only" ]; then
                ensure_backup_dir
                backup_configs
            else
                backup_full
            fi
            ;;

        restore)
            if [ "$2" == "--file" ] && [ -n "$3" ]; then
                if [ ! -f "$3" ]; then
                    print_error "Backup file not found: $3"
                    exit 1
                fi

                if [[ "$3" == *"db_backup"* ]]; then
                    restore_databases "$3"
                elif [[ "$3" == *"config_backup"* ]]; then
                    restore_configs "$3"
                else
                    print_error "Unknown backup type"
                    exit 1
                fi
            else
                print_error "Please specify backup file with --file option"
                usage
            fi
            ;;

        list)
            list_backups
            ;;

        clean)
            clean_backups
            ;;

        *)
            usage
            ;;
    esac
}

# Run main function
main "$@"