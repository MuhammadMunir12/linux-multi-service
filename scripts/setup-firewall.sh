#!/usr/bin/env bash

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

source "$SCRIPT_DIR/common.sh"

require_root

log "Setting up UFW firewall"

require_command ufw

if ! ufw status | grep -q "Status: active"; then
    log "Configuring UFW default policies"

    ufw default deny incoming
    ufw default allow outgoing

    log "Allowing SSH"

    if ! ufw status | grep -qE '22/tcp[[:space:]]+ALLOW'; then
        ufw allow 22/tcp
    else
        log "SSH rule already exists"
    fi

    log "Allowing HTTP"

    if ! ufw status | grep -qE '80/tcp[[:space:]]+ALLOW'; then
        ufw allow 80/tcp
    else
        log "HTTP rule already exists"
    fi

    log "Enabling UFW"

    ufw --force enable
else
    log "UFW is already active"

    log "Ensuring SSH rule exists"

    if ! ufw status | grep -qE '22/tcp[[:space:]]+ALLOW'; then
        ufw allow 22/tcp
    fi

    log "Ensuring HTTP rule exists"

    if ! ufw status | grep -qE '80/tcp[[:space:]]+ALLOW'; then
        ufw allow 80/tcp
    fi
fi

log "Current firewall status"

ufw status verbose

log "UFW firewall configured successfully"
