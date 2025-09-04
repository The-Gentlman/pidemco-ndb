#!/bin/bash
set -e

DB_USER="nocobase"
DB_NAME="nocobase"
DB_CONTAINER="nocobase-db"

BACKUP_FILE="db.sql"

if [ -z "$BACKUP_FILE" ]; then
    echo -e "\033[31m[ERROR]\033[0m No backup file found! Provide one as argument or run backup first."
    exit 1
fi

BLUE="\033[34m"
GREEN="\033[32m"
RED="\033[31m"
BOLD="\033[1m"
RESET="\033[0m"

echo -e "${BLUE}${BOLD}[INFO]${RESET} Starting database restore process..."
echo -e "${BLUE}${BOLD}[INFO]${RESET} Using backup file: ${BACKUP_FILE}"

echo -e "${BLUE}${BOLD}[INFO]${RESET} Terminating active database connections..."
docker exec -u postgres "$DB_CONTAINER" psql -c "
    SELECT pg_terminate_backend(pg_stat_activity.pid)
    FROM pg_stat_activity
    WHERE pg_stat_activity.datname = '$DB_NAME' AND pid <> pg_backend_pid();
" > /dev/null 2>&1

# 2. Drop and recreate database
echo -e "${BLUE}${BOLD}[INFO]${RESET} Dropping existing database..."
docker exec "$DB_CONTAINER" dropdb -U "$DB_USER" "$DB_NAME" || true
echo -e "${BLUE}${BOLD}[INFO]${RESET} Creating new database..."
docker exec "$DB_CONTAINER" createdb -U "$DB_USER" "$DB_NAME"

# 3. Restore database
echo -e "${BLUE}${BOLD}[INFO]${RESET} Restoring database from backup..."
docker exec -i "$DB_CONTAINER" pg_restore -U "$DB_USER" -d "$DB_NAME" --clean --if-exists < "$BACKUP_FILE"

echo -e "${GREEN}${BOLD}[SUCCESS]${RESET} Database restored successfully!"
