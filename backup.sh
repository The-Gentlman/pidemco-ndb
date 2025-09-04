#!/bin/bash
set -e

DB_USER="nocobase"
DB_NAME="nocobase"
DB_CONTAINER="na-db-1"
DATE=$(date +"%Y-%m-%d")
BACKUP_FILE="db.sql"

BLUE="\033[34m"
GREEN="\033[32m"
RED="\033[31m"
BOLD="\033[1m"
RESET="\033[0m"

trap 'error_handler' ERR

echo -e "${BLUE}${BOLD}[INFO]${RESET} Start backup process..."

error_handler() {
    echo -e "${RED}${BOLD}[ERROR]${RESET} An error occurred during backup."
    exit 1
}

echo -e "${BLUE}${BOLD}[INFO]${RESET} Database dump started..."
docker exec "$DB_CONTAINER" pg_dump -U "$DB_USER" "$DB_NAME" -Fc > "$BACKUP_FILE"

echo -e "${GREEN}${BOLD}[SUCCESS]${RESET} Database dumped successfully to ${BACKUP_FILE}!"
