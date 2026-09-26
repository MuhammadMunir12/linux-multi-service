#!/usr/bin/env bash

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"

source "$SCRIPT_DIR/common.sh"

require_root

SOURCE_CRON="$PROJECT_ROOT/cron/linux-multi-service"
TARGET_CRON="/etc/cron.d/linux-multi-service"

log "Setting up monitoring"

if [[ ! -f "$SOURCE_CRON" ]]; then
    die "Cron configuration not found: $SOURCE_CRON"
fi

require_command systemctl

if ! systemctl is-active --quiet cron; then
    log "Starting cron service"
    systemctl enable --now cron
else
    log "Cron service is already running"
fi

log "Installing monitoring cron configuration"

cp "$SOURCE_CRON" "$TARGET_CRON"
chmod 644 "$TARGET_CRON"

log "Monitoring cron job configured successfully"
