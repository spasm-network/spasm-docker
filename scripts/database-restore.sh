#!/bin/bash
set -euo pipefail

if [ "$#" -ne 1 ]; then
  echo "Usage: $0 /path/to/backup.sql[.gz]"
  exit 2
fi

BACKUP_PATH="$1"

if [ ! -f "$BACKUP_PATH" ]; then
  echo "❌ Error: backup file not found: $BACKUP_PATH"
  exit 1
fi

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_DIR="$(dirname "$SCRIPT_DIR")"

if [ -f "$PROJECT_DIR/.env" ]; then
  set -a
  source "$PROJECT_DIR/.env"
  set +a
fi

POSTGRES_DATABASE="${POSTGRES_DATABASE:-spasm_database}"
POSTGRES_USER="${POSTGRES_USER:-spasm_user}"
POSTGRES_PASSWORD="${POSTGRES_PASSWORD:-spasm_password}"
PROJECT_NAME="${COMPOSE_PROJECT_NAME:-$(basename "$PROJECT_DIR")}"

VOLUME_NAME="${PROJECT_NAME}_postgres-volume"
NETWORK_NAME="${PROJECT_NAME}_network-internal"

echo "🔍 Project: $PROJECT_NAME"
echo "📥 Restore file: $BACKUP_PATH"
echo "📦 Target DB: $POSTGRES_DATABASE"

if command -v docker >/dev/null 2>&1; then
  CONTAINER_CMD=docker
elif command -v podman >/dev/null 2>&1; then
  CONTAINER_CMD=podman
else
  echo "❌ Error: neither docker nor podman found"
  exit 1
fi

echo "Using runtime: $CONTAINER_CMD"

if ! $CONTAINER_CMD volume inspect "$VOLUME_NAME" > /dev/null 2>&1; then
  echo "❌ Error: Volume '$VOLUME_NAME' not found!"
  exit 1
fi

if [[ "$BACKUP_PATH" == *.gz ]]; then
  DECOMP_CMD="gzip -dc"
else
  DECOMP_CMD="cat"
fi

POSTGRES_CONTAINER=$($CONTAINER_CMD ps --filter "label=com.docker.compose.service=postgres" --filter "label=com.docker.compose.project=$PROJECT_NAME" -q 2>/dev/null | head -1 || true)

# Helper: run SQL command via psql in a postgres:16 helper container (networked)
run_psql_network() {
  local sql="$1"
  $CONTAINER_CMD run --rm --network "$NETWORK_NAME" -i \
    -e PGPASSWORD="$POSTGRES_PASSWORD" \
    postgres:16 \
    psql -h "${POSTGRES_HOST:-postgres}" -U "$POSTGRES_USER" -d "postgres" -c "$sql"
}

if [ -n "$POSTGRES_CONTAINER" ]; then
  echo "✅ PostgreSQL container running — dropping & recreating DB over network"

  POSTGRES_HOST="${POSTGRES_HOST:-postgres}"
  POSTGRES_PORT="${POSTGRES_PORT:-5432}"

  echo "Dropping database if exists..."
  run_psql_network "ALTER DATABASE \"$POSTGRES_DATABASE\" CONNECTION LIMIT 0;" >/dev/null 2>&1 || true
  run_psql_network "SELECT pg_terminate_backend(pid) FROM pg_stat_activity WHERE datname = '$POSTGRES_DATABASE';" || true
  run_psql_network "DROP DATABASE IF EXISTS \"$POSTGRES_DATABASE\";"
  run_psql_network "CREATE DATABASE \"$POSTGRES_DATABASE\" OWNER \"$POSTGRES_USER\";"

  echo "Restoring dump..."
  $DECOMP_CMD "$BACKUP_PATH" | \
    $CONTAINER_CMD run --rm --network "$NETWORK_NAME" -i \
      -e PGPASSWORD="$POSTGRES_PASSWORD" \
      postgres:16 \
      psql -h "$POSTGRES_HOST" -U "$POSTGRES_USER" -d "$POSTGRES_DATABASE"

  echo "✅ Restore completed"
  exit 0
else
  echo "⚠️ PostgreSQL container is down — starting temporary container to mount volume"

  TEMP_CONTAINER=$($CONTAINER_CMD run -d \
    --volume "$VOLUME_NAME:/var/lib/postgresql/data" \
    postgres:16)

  echo "⏳ Waiting for temporary PostgreSQL..."
  READY=false
  for i in {1..12}; do
    if $CONTAINER_CMD exec "$TEMP_CONTAINER" bash -c "pg_isready -q"; then
      READY=true
      break
    fi
    sleep 5
  done

  if [ "$READY" != true ]; then
    echo "❌ Temporary PostgreSQL did not become ready"
    $CONTAINER_CMD stop "$TEMP_CONTAINER" 2>/dev/null || true
    $CONTAINER_CMD rm "$TEMP_CONTAINER" 2>/dev/null || true
    exit 1
  fi

  echo "✅ Temporary PostgreSQL ready — dropping & recreating DB inside container"

  # Terminate connections, drop & create DB
  $CONTAINER_CMD exec "$TEMP_CONTAINER" bash -c "psql -U '$POSTGRES_USER' -d postgres -c \"SELECT pg_terminate_backend(pid) FROM pg_stat_activity WHERE datname = '$POSTGRES_DATABASE';\" || true"
  $CONTAINER_CMD exec "$TEMP_CONTAINER" bash -c "psql -U '$POSTGRES_USER' -d postgres -c \"DROP DATABASE IF EXISTS \\\"$POSTGRES_DATABASE\\\";\""
  $CONTAINER_CMD exec "$TEMP_CONTAINER" bash -c "psql -U '$POSTGRES_USER' -d postgres -c \"CREATE DATABASE \\\"$POSTGRES_DATABASE\\\" OWNER \\\"$POSTGRES_USER\\\";\""

  echo "Copying backup into container..."
  BASENAME="$(basename "$BACKUP_PATH")"
  $CONTAINER_CMD cp "$BACKUP_PATH" "$TEMP_CONTAINER:/tmp/$BASENAME"

  echo "Running restore..."
  if [[ "$BACKUP_PATH" == *.gz ]]; then
    $CONTAINER_CMD exec -i "$TEMP_CONTAINER" bash -c "gzip -dc /tmp/$BASENAME | PGPASSWORD='$POSTGRES_PASSWORD' psql -U '$POSTGRES_USER' -d '$POSTGRES_DATABASE'"
  else
    $CONTAINER_CMD exec -i "$TEMP_CONTAINER" bash -c "cat /tmp/$BASENAME | PGPASSWORD='$POSTGRES_PASSWORD' psql -U '$POSTGRES_USER' -d '$POSTGRES_DATABASE'"
  fi

  RESULT=$?

  echo "🧹 Cleaning up temporary container..."
  $CONTAINER_CMD stop "$TEMP_CONTAINER" 2>/dev/null || true
  $CONTAINER_CMD rm "$TEMP_CONTAINER" 2>/dev/null || true

  if [ $RESULT -eq 0 ]; then
    echo "✅ Restore completed"
    exit 0
  else
    echo "❌ Restore failed"
    exit $RESULT
  fi
fi
