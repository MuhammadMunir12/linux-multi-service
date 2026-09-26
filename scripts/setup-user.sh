#!/usr/bin/env bash

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/common.sh"

require_root

WEBAPP_USER="webapp"
WEBAPP_GROUP="webapp"
WEBAPP_ROOT="/opt/webapp"

log "Setting up webapp user and directories"

if id "$WEBAPP_USER" >/dev/null 2>&1; then
    log "User '$WEBAPP_USER' already exists"
else
    useradd \
        --system \
        --create-home \
        --shell /usr/sbin/nologin \
        "$WEBAPP_USER"

    log "Created system user '$WEBAPP_USER'"
fi

mkdir -p \
    "$WEBAPP_ROOT/app" \
    "$WEBAPP_ROOT/logs" \
    "$WEBAPP_ROOT/config"

chown -R "$WEBAPP_USER:$WEBAPP_GROUP" "$WEBAPP_ROOT"

chmod 755 "$WEBAPP_ROOT"
chmod 755 "$WEBAPP_ROOT/app"
chmod 755 "$WEBAPP_ROOT/config"
chmod 750 "$WEBAPP_ROOT/logs"

log "Webapp user and directories configured"
