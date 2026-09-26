#!/usr/bin/env bash

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"

source "$SCRIPT_DIR/common.sh"

require_root

SERVICE_NAME="webapp.service"
SOURCE_SERVICE="$PROJECT_ROOT/systemd/webapp.service"
TARGET_SERVICE="/etc/systemd/system/$SERVICE_NAME"

log "Setting up systemd service"

require_command systemctl
require_command ss

if [[ ! -f "$SOURCE_SERVICE" ]]; then
    die "Systemd service file not found: $SOURCE_SERVICE"
fi

log "Installing $SERVICE_NAME"

cp "$SOURCE_SERVICE" "$TARGET_SERVICE"
chmod 644 "$TARGET_SERVICE"

log "Reloading systemd configuration"

systemctl daemon-reload

log "Enabling $SERVICE_NAME"

systemctl enable "$SERVICE_NAME"

log "Starting $SERVICE_NAME"

systemctl restart "$SERVICE_NAME"

log "Checking service status"

if ! systemctl is-active --quiet "$SERVICE_NAME"; then
    systemctl status "$SERVICE_NAME" --no-pager
    die "$SERVICE_NAME is not running"
fi

log "$SERVICE_NAME is active"

log "Waiting for webapp to listen on 127.0.0.1:3000"

WEBAPP_READY=false

for _ in {1..10}; do
    if ss -ltn | grep -q '127.0.0.1:3000'; then
        WEBAPP_READY=true
        break
    fi

    sleep 1
done

if [[ "$WEBAPP_READY" != "true" ]]; then
    log "Webapp did not start listening within 10 seconds"
    systemctl status "$SERVICE_NAME" --no-pager
    die "Webapp is not listening on 127.0.0.1:3000"
fi

log "Webapp is listening on 127.0.0.1:3000"
log "Systemd service configured successfully"
