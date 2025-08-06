#!/bin/bash
set -e

# OpenSPP Docker Entrypoint Script

# Function to set default configuration
set_conf() {
    echo "Setting configuration: $1 = $2"
    if ! grep -q "^$1" "$ODOO_RC"; then
        echo "$1 = $2" >> "$ODOO_RC"
    else
        sed -i "s/^$1.*/$1 = $2/" "$ODOO_RC"
    fi
}

# Create configuration file if it doesn't exist
if [ ! -f "$ODOO_RC" ]; then
    echo "Creating OpenSPP configuration file..."
    cp /etc/openspp/openspp.conf.template "$ODOO_RC" 2>/dev/null || touch "$ODOO_RC"
fi

# Set database parameters from environment variables
if [ "$HOST" != "" ]; then
    set_conf "db_host" "$HOST"
fi

if [ "$PORT" != "" ]; then
    set_conf "db_port" "$PORT"
fi

if [ "$USER" != "" ]; then
    set_conf "db_user" "$USER"
fi

if [ "$PASSWORD" != "" ]; then
    set_conf "db_password" "$PASSWORD"
fi

# Set addons path to include OpenSPP modules
ADDONS_PATH="/mnt/openspp-addons"

# Add Odoo standard addons
if [ -d "/usr/lib/python3/dist-packages/odoo/addons" ]; then
    ADDONS_PATH="${ADDONS_PATH},/usr/lib/python3/dist-packages/odoo/addons"
fi

# Add extra addons if mounted
if [ -d "/mnt/extra-addons" ] && [ "$(ls -A /mnt/extra-addons)" ]; then
    ADDONS_PATH="${ADDONS_PATH},/mnt/extra-addons"
fi

set_conf "addons_path" "$ADDONS_PATH"

# Set server-wide modules if not set
if [ -z "$SERVER_WIDE_MODULES" ]; then
    export SERVER_WIDE_MODULES="base,web"
fi
set_conf "server_wide_modules" "$SERVER_WIDE_MODULES"

# Set default productivity apps
set_conf "default_productivity_apps" "True"

# Wait for PostgreSQL if needed
if [ "$WAIT_DB" = "true" ]; then
    echo "Waiting for PostgreSQL to be ready..."
    DB_HOST="${HOST:-db}"
    DB_PORT="${PORT:-5432}"
    
    for i in {1..30}; do
        if pg_isready -h "$DB_HOST" -p "$DB_PORT" -U "${USER:-odoo}" >/dev/null 2>&1; then
            echo "PostgreSQL is ready!"
            break
        fi
        echo "Waiting for PostgreSQL... ($i/30)"
        sleep 2
    done
fi

# Initialize database if requested
if [ "$INIT_MODULES" != "" ]; then
    echo "Initializing database with modules: $INIT_MODULES"
    set -- "$@" "-i" "$INIT_MODULES"
fi

# Update modules if requested
if [ "$UPDATE_MODULES" != "" ]; then
    echo "Updating modules: $UPDATE_MODULES"
    set -- "$@" "-u" "$UPDATE_MODULES"
fi

# Development mode settings
if [ "$DEV_MODE" = "true" ]; then
    echo "Running in development mode..."
    set_conf "log_level" "debug"
    set_conf "log_handler" ":DEBUG"
    set_conf "reload" "True"
fi

# Performance tuning
if [ "$WORKERS" != "" ]; then
    set_conf "workers" "$WORKERS"
fi

if [ "$MAX_CRON_THREADS" != "" ]; then
    set_conf "max_cron_threads" "$MAX_CRON_THREADS"
fi

if [ "$LIMIT_MEMORY_SOFT" != "" ]; then
    set_conf "limit_memory_soft" "$LIMIT_MEMORY_SOFT"
fi

if [ "$LIMIT_MEMORY_HARD" != "" ]; then
    set_conf "limit_memory_hard" "$LIMIT_MEMORY_HARD"
fi

if [ "$LIMIT_TIME_CPU" != "" ]; then
    set_conf "limit_time_cpu" "$LIMIT_TIME_CPU"
fi

if [ "$LIMIT_TIME_REAL" != "" ]; then
    set_conf "limit_time_real" "$LIMIT_TIME_REAL"
fi

# Create required directories
mkdir -p /var/lib/openspp/data
mkdir -p /var/lib/openspp/sessions
mkdir -p /var/lib/openspp/filestore

# Fix permissions
chown -R odoo:odoo /var/lib/openspp

echo "=========================================="
echo "OpenSPP Version: $OPENSPP_VERSION"
echo "Odoo Version: $ODOO_VERSION"
echo "Configuration: $ODOO_RC"
echo "Addons Path: $ADDONS_PATH"
echo "=========================================="

# Execute the original Odoo entrypoint
exec /entrypoint.sh "$@"