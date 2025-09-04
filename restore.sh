#!/bin/bash
set -e

# ======= CONFIG =======
DB_USER="nocobase"
DB_NAME="nocobase"
DB_CONTAINER="nocobase-db"
BACKUP_FILE="db.sql"   # can be .sql or .dump

# ======= COLORS =======
BLUE="\033[34m"
GREEN="\033[32m"
YELLOW="\033[33m"
RED="\033[31m"
BOLD="\033[1m"
RESET="\033[0m"

function log_info {
    echo -e "${BLUE}${BOLD}[INFO]${RESET} $1"
}

function log_warn {
    echo -e "${YELLOW}${BOLD}[WARN]${RESET} $1"
}

function log_success {
    echo -e "${GREEN}${BOLD}[SUCCESS]${RESET} $1"
}

function log_error {
    echo -e "${RED}${BOLD}[ERROR]${RESET} $1"
}

# ======= CHECKS =======
if [ ! -f "$BACKUP_FILE" ]; then
    log_error "Backup file '$BACKUP_FILE' not found!"
    exit 1
fi

log_info "Starting database restore process..."
log_info "Using backup file: $BACKUP_FILE"

# Detect file type (plain SQL vs custom-format)
FILE_TYPE=$(file "$BACKUP_FILE")
IS_CUSTOM=false
if echo "$FILE_TYPE" | grep -qi "PostgreSQL custom database dump"; then
    IS_CUSTOM=true
    log_info "Detected custom-format PostgreSQL dump."
else
    log_info "Detected plain SQL dump."
fi

# ======= TERMINATE CONNECTIONS =======
log_info "Terminating active connections to '$DB_NAME'..."
if ! docker exec "$DB_CONTAINER" psql -U "$DB_USER" -d postgres -c "
    SELECT pg_terminate_backend(pg_stat_activity.pid)
    FROM pg_stat_activity
    WHERE pg_stat_activity.datname = '$DB_NAME'
    AND pid <> pg_backend_pid();
" >/dev/null 2>&1; then
    log_warn "Could not terminate connections (possibly none active)."
fi

# ======= DROP & CREATE DB =======
log_info "Dropping existing database..."
docker exec "$DB_CONTAINER" dropdb -U "$DB_USER" --if-exists "$DB_NAME" || true

log_info "Creating fresh database..."
docker exec "$DB_CONTAINER" createdb -U "$DB_USER" "$DB_NAME"

# ======= RESTORE =======
log_info "Restoring database..."
if [ "$IS_CUSTOM" = true ]; then
    # custom format
    docker exec -i "$DB_CONTAINER" pg_restore -U "$DB_USER" -d "$DB_NAME" --clean --if-exists < "$BACKUP_FILE"
else
    # plain SQL
    docker exec -i "$DB_CONTAINER" psql -U "$DB_USER" -d "$DB_NAME" < "$BACKUP_FILE"
fi

log_success "Database restored successfully!"
