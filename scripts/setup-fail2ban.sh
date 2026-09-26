#!/usr/bin/env bash

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"

source "$SCRIPT_DIR/common.sh"

require_root

SOURCE_JAIL="$PROJECT_ROOT/fail2ban/jail.local"
TARGET_JAIL="/etc/fail2ban/jail.local"

log "Setting up fail2ban"

require_command apt-get
require_command systemctl
require_command fail2ban-client

if [[ ! -f "$SOURCE_JAIL" ]]; then
    die "fail2ban configuration not found: $SOURCE_JAIL"
fi

if ! dpkg -s fail2ban >/dev/null 2>&1; then
    log "Installing fail2ban"

    apt-get update
    apt-get install -y fail2ban
else
    log "fail2ban is already installed"
fi

log "Installing fail2ban configuration"

cp "$SOURCE_JAIL" "$TARGET_JAIL"
chmod 644 "$TARGET_JAIL"

log "Validating fail2ban configuration"

if ! fail2ban-client -t; then
    die "fail2ban configuration validation failed"
fi

log "Enabling fail2ban"

systemctl enable fail2ban

log "Restarting fail2ban"

systemctl restart fail2ban

if ! systemctl is-active --quiet fail2ban; then
    systemctl status fail2ban --no-pager
    die "fail2ban is not running"
fi

log "Waiting for fail2ban jails to become available"

SSH_JAIL_READY=false
NGINX_JAIL_READY=false

for _ in {1..10}; do
    if fail2ban-client status sshd >/dev/null 2>&1; then
        SSH_JAIL_READY=true
    fi

    if fail2ban-client status nginx-bad-request >/dev/null 2>&1; then
        NGINX_JAIL_READY=true
    fi

    if [[ "$SSH_JAIL_READY" == "true" && "$NGINX_JAIL_READY" == "true" ]]; then
        break
    fi

    sleep 1
done

if [[ "$SSH_JAIL_READY" != "true" ]]; then
    log "SSH jail did not become available within 10 seconds"
    fail2ban-client status
    die "SSH fail2ban jail is not active"
fi

if [[ "$NGINX_JAIL_READY" != "true" ]]; then
    log "Nginx jail did not become available within 10 seconds"
    fail2ban-client status
    die "Nginx fail2ban jail is not active"
fi

log "SSH fail2ban jail is active"
log "Nginx fail2ban jail is active"

log "fail2ban configured successfully"
