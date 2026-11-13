#!/bin/bash
set -euo pipefail

# =============================================================================
# Entrypoint wrapper — substitutes environment variables into odoo.conf before
# launching the official Odoo entrypoint.
# =============================================================================

# Substitute env vars in odoo.conf using envsubst
# Only replace the specific variables we use
export ADMIN_PASSWD="${ADMIN_PASSWD:-admin}"
export DB_HOST="${HOST:-db}"
export DB_PORT="${DB_PORT:-5432}"
export DB_USER="${USER:-odoo}"
export DB_PASSWORD="${PASSWORD:-odoo}"

envsubst < /etc/odoo/odoo.conf > /tmp/odoo.conf.substituted
cp /tmp/odoo.conf.substituted /etc/odoo/odoo.conf

# Wait for PostgreSQL to be ready
echo "Waiting for PostgreSQL at ${DB_HOST}:${DB_PORT}..."
for i in $(seq 1 30); do
    if pg_isready -h "${DB_HOST}" -p "${DB_PORT}" -U "${DB_USER}" >/dev/null 2>&1; then
        echo "PostgreSQL is ready."
        break
    fi
    echo "  Attempt $i/30 — PostgreSQL not ready yet, retrying in 2s..."
    sleep 2
done

# Hand off to the official Odoo entrypoint
exec /entrypoint.sh odoo
