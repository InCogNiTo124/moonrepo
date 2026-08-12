#!/usr/bin/env bash
set -e

echo "Ensuring local database is up..."
docker compose -f docker-compose.yml -f docker-compose.local.yml up -d db

echo "Waiting for postgres to be ready..."
sleep 3

# Prod DB details from runtime.exs
PROD_HOST="${DATABASE_HOST:-postgres4a-exoscale-3f1ca88f-2ed3-4886-8817-f8ce726f9357.j.aivencloud.com}"
PROD_PORT="${DATABASE_PORT:-21699}"
PROD_DB="jaja"
PROD_USER="${DATABASE_USER}"
PROD_PASS="${DATABASE_PASSWORD}"

if [ -z "$PROD_USER" ] || [ -z "$PROD_PASS" ]; then
    echo "Error: DATABASE_USER and DATABASE_PASSWORD must be set to pull prod data."
    exit 1
fi

echo "Dumping production database using docker..."
docker run --rm -v /tmp:/tmp -e PGPASSWORD=$PROD_PASS postgres:17 pg_dump -h $PROD_HOST -p $PROD_PORT -U $PROD_USER -d $PROD_DB -F c -f /tmp/prod_data.dump

echo "Dropping and recreating local database..."
docker compose -f docker-compose.yml -f docker-compose.local.yml exec -T db psql -U postgres -d postgres -c "DROP DATABASE IF EXISTS jaja;"
docker compose -f docker-compose.yml -f docker-compose.local.yml exec -T db psql -U postgres -d postgres -c "CREATE DATABASE jaja;"

echo "Restoring data to local database..."
docker run --rm -v /tmp:/tmp --network container:$(docker compose -f docker-compose.yml -f docker-compose.local.yml ps -q db) postgres:17 pg_restore -U postgres -d jaja -h 127.0.0.1 -1 -F c --no-owner --no-privileges /tmp/prod_data.dump || true

echo "Done! You can now run local docker with: docker compose -f docker-compose.yml -f docker-compose.local.yml up"
