#!/usr/bin/env bash

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"

source "$SCRIPT_DIR/common.sh"

require_root

WEBAPP_USER="webapp"
WEBAPP_GROUP="webapp"
LOG_DIR="/var/log/webapp"
LOG_FILE="$LOG_DIR/app.log"

SOURCE_LOGROTATE="$PROJECT_ROOT/logrotate/webapp"
TARGET_LOGROTATE="/etc/logrotate.d/webapp"

log "Setting up application logging"

require_command apt-get
require_command logrotate

if ! id "$WEBAPP_USER" >/dev/null 2>&1; then
    die "Required user '$WEBAPP_USER' does not exist. Run setup-user.sh first."
fi

if [[ ! -f "$SOURCE_LOGROTATE" ]]; then
    die "Logrotate configuration not found: $SOURCE_LOGROTATE"
fi

if [[ ! -d "$LOG_DIR" ]]; then
    log "Creating application log directory"
    mkdir -p "$LOG_DIR"
else
    log "Application log directory already exists"
fi

if [[ ! -f "$LOG_FILE" ]]; then
    log "Creating application log file"
    touch "$LOG_FILE"
fi

chown "$WEBAPP_USER:$WEBAPP_GROUP" "$LOG_DIR"
chown "$WEBAPP_USER:$WEBAPP_GROUP" "$LOG_FILE"

chmod 750 "$LOG_DIR"
chmod 640 "$LOG_FILE"

log "Installing logrotate configuration"

cp "$SOURCE_LOGROTATE" "$TARGET_LOGROTATE"
chmod 644 "$TARGET_LOGROTATE"

log "Validating logrotate configuration"

if ! logrotate -d "$TARGET_LOGROTATE" >/dev/null; then
    die "Logrotate configuration validation failed"
fi

log "Application logging configured successfully"
