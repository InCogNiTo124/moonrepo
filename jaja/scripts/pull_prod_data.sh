#!/usr/bin/env bash
set -euo pipefail

# Pull the production jaja database into the local docker postgres.
#
# Prod is no longer Aiven: it is the host-level PostgreSQL on cosmos, which is
# deliberately unreachable from here -- the Hetzner firewall keeps 5432 closed
# and pg_hba admits only loopback plus the pod CIDR (see
# cosmos/cloud-init.d/postgres-files.j2). So the dump is taken *on* the server
# and streamed down over ssh.
#
# Running pg_dump as the postgres system user gets peer auth, so this script
# needs no database credentials at all -- only ssh access.

SSH_HOST="${COSMOS_SSH_HOST:-cosmos}"
DUMP="${DUMP_FILE:-/tmp/prod_data.dump}"
COMPOSE=(docker compose -f docker-compose.yml -f docker-compose.local.yml)

echo "Ensuring local database is up..."
"${COMPOSE[@]}" up -d db

echo "Waiting for postgres to be ready..."
until "${COMPOSE[@]}" exec -T db pg_isready -U postgres -q 2>/dev/null; do sleep 1; done

echo "Dumping production database from ${SSH_HOST}..."
ssh "$SSH_HOST" 'sudo -u postgres pg_dump -Fc jaja' > "$DUMP"
echo "  $(wc -c < "$DUMP") bytes"

echo "Dropping and recreating local database..."
"${COMPOSE[@]}" exec -T db psql -U postgres -d postgres -q -c "DROP DATABASE IF EXISTS jaja;"
"${COMPOSE[@]}" exec -T db psql -U postgres -d postgres -q -c "CREATE DATABASE jaja;"

# Restore inside the db container so the client major always matches the server
# it is loading into. Prod objects are owned by the jaja role, which does not
# exist locally, hence --no-owner/--no-privileges.
echo "Restoring data to local database..."
"${COMPOSE[@]}" exec -T db pg_restore -U postgres -d jaja --no-owner --no-privileges < "$DUMP"

echo "Done! Start the app with:"
echo "  docker compose -f docker-compose.yml -f docker-compose.local.yml up"
