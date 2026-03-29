#!/bin/bash
# Database is backed as .sql.gz
# You can verify database backup with zcat, e.g.:
# zcat spasm-docker_spasm_database_20260101-33333.sql.gz | grep -n "genesis"
set -euo pipefail

# Get script directory
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_DIR="$(dirname "$SCRIPT_DIR")"

# Load environment variables
if [ -f "$PROJECT_DIR/.env" ]; then
  set -a
  source "$PROJECT_DIR/.env"
  set +a
fi

# Set defaults
POSTGRES_DATABASE="${POSTGRES_DATABASE:-spasm_database}"
POSTGRES_USER="${POSTGRES_USER:-spasm_user}"
POSTGRES_PASSWORD="${POSTGRES_PASSWORD:-spasm_password}"

# Get project name
PROJECT_NAME="${COMPOSE_PROJECT_NAME:-$(basename "$PROJECT_DIR")}"

# Create backups directory
BACKUPS_DIR="$PROJECT_DIR/backups"
mkdir -p "$BACKUPS_DIR"

# Generate backup filename
TIMESTAMP=$(date '+%Y%m%d-%H%M')
BACKUP_FILE="$BACKUPS_DIR/${PROJECT_NAME}_${POSTGRES_DATABASE}_${TIMESTAMP}.sql.gz"

echo "🔍 Project name: $PROJECT_NAME"
echo "📦 Database: $POSTGRES_DATABASE"
echo "💾 Backup file: $BACKUP_FILE"

# Choose container runtime
if command -v docker >/dev/null 2>&1; then
  CONTAINER_CMD=docker
elif command -v podman >/dev/null 2>&1; then
  CONTAINER_CMD=podman
else
  echo "❌ Error: neither docker nor podman found"
  exit 1
fi

echo "Using container runtime: $CONTAINER_CMD"

# Get the volume and network names
VOLUME_NAME="${PROJECT_NAME}_postgres-volume"
NETWORK_NAME="${PROJECT_NAME}_network-internal"

echo "🔎 Looking for volume: $VOLUME_NAME"

# Check if volume exists
if ! $CONTAINER_CMD volume inspect "$VOLUME_NAME" > /dev/null 2>&1; then
  echo "❌ Error: Volume '$VOLUME_NAME' not found!"
  exit 1
fi

echo "✅ Volume found"
echo "⏳ Backing up database..."

# Check if PostgreSQL container is actually running
POSTGRES_CONTAINER=$($CONTAINER_CMD ps --filter "label=com.docker.compose.service=postgres" --filter "label=com.docker.compose.project=$PROJECT_NAME" -q 2>/dev/null | head -1)

if [ -n "$POSTGRES_CONTAINER" ]; then
  echo "✅ PostgreSQL container is running, using network connection"

  POSTGRES_HOST="${POSTGRES_HOST:-postgres}"
  POSTGRES_PORT="${POSTGRES_PORT:-5432}"

  $CONTAINER_CMD run --rm \
    --volume "$VOLUME_NAME:/var/lib/postgresql/data" \
    --network "$NETWORK_NAME" \
    -e PGPASSWORD="$POSTGRES_PASSWORD" \
    postgres:16 \
    pg_dump \
      -h "$POSTGRES_HOST" \
      -U "$POSTGRES_USER" \
      -d "$POSTGRES_DATABASE" \
      -p "$POSTGRES_PORT" \
    | gzip -9 \
    > "$BACKUP_FILE"
else
  echo "⚠️  PostgreSQL container is down, starting temporary PostgreSQL..."

  # Start temporary container
  TEMP_CONTAINER=$($CONTAINER_CMD run -d \
    --volume "$VOLUME_NAME:/var/lib/postgresql/data" \
    postgres:16)

  echo "⏳ Waiting for temporary PostgreSQL to start..."
  sleep 5

  # Backup from temp container with compression
  if $CONTAINER_CMD exec "$TEMP_CONTAINER" \
    bash -c "PGPASSWORD='$POSTGRES_PASSWORD' pg_dump -U '$POSTGRES_USER' -d '$POSTGRES_DATABASE'" \
    | gzip -9 \
    > "$BACKUP_FILE"; then
    BACKUP_SUCCESS=true
  else
    BACKUP_SUCCESS=false
  fi

  # Stop and remove temp container
  echo "🧹 Cleaning up temporary container..."
  $CONTAINER_CMD stop "$TEMP_CONTAINER" 2>/dev/null || true
  $CONTAINER_CMD rm "$TEMP_CONTAINER" 2>/dev/null || true

  if [ "$BACKUP_SUCCESS" = false ]; then
    echo "❌ Backup failed!"
    exit 1
  fi
fi

# Check if backup was successful
if [ -f "$BACKUP_FILE" ]; then
  SIZE=$(du -h "$BACKUP_FILE" | cut -f1)
  echo "✅ Backup successful!"
  echo "📁 Location: $BACKUP_FILE"
  echo "📊 Size: $SIZE"
else
  echo "❌ Backup failed!"
  exit 1
fi
