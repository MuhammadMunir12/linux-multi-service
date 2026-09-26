#!/usr/bin/env bash

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"

source "$SCRIPT_DIR/common.sh"

require_root

WEBAPP_USER="webapp"
WEBAPP_GROUP="webapp"
WEBAPP_ROOT="/opt/webapp"
APP_DIR="$WEBAPP_ROOT/app"
VENV_DIR="$WEBAPP_ROOT/venv"

SOURCE_APP="$PROJECT_ROOT/app/app.py"
SOURCE_REQUIREMENTS="$PROJECT_ROOT/app/requirements.txt"

log "Setting up Python backend"

require_command apt-get
require_command python3
require_command runuser

if [[ ! -f "$SOURCE_APP" ]]; then
    die "Application file not found: $SOURCE_APP"
fi

if [[ ! -f "$SOURCE_REQUIREMENTS" ]]; then
    die "Requirements file not found: $SOURCE_REQUIREMENTS"
fi

if ! id "$WEBAPP_USER" >/dev/null 2>&1; then
    die "Required user '$WEBAPP_USER' does not exist. Run setup-user.sh first."
fi

log "Installing Python virtual environment support"

apt-get update
apt-get install -y python3-venv

log "Creating application directory"

mkdir -p "$APP_DIR"

log "Deploying application files"

cp "$SOURCE_APP" "$APP_DIR/app.py"
cp "$SOURCE_REQUIREMENTS" "$APP_DIR/requirements.txt"

if [[ ! -d "$VENV_DIR" ]]; then
    log "Creating Python virtual environment"

    runuser -u "$WEBAPP_USER" -- \
        python3 -m venv "$VENV_DIR"
else
    log "Python virtual environment already exists"
fi

log "Installing Python dependencies"

runuser -u "$WEBAPP_USER" -- \
    "$VENV_DIR/bin/pip" install \
    --disable-pip-version-check \
    -r "$APP_DIR/requirements.txt"

log "Setting application ownership and permissions"

chown -R "$WEBAPP_USER:$WEBAPP_GROUP" "$APP_DIR"
chown -R "$WEBAPP_USER:$WEBAPP_GROUP" "$VENV_DIR"

chmod 755 "$APP_DIR"

log "Python backend configured successfully"
