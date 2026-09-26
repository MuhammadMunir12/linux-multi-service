#!/usr/bin/env bash

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

source "$SCRIPT_DIR/common.sh"

require_root

log "Starting environment validation"

require_command curl
require_command getent
require_command ss
require_command systemctl
require_command ufw
require_command fail2ban-client
require_command logrotate

log "Checking required services"

for service in webapp nginx fail2ban; do
    if systemctl is-active --quiet "$service"; then
        log "$service is active"
    else
        die "$service is not active"
    fi
done

log "Checking required listening ports"

if ss -ltn | grep -q '127.0.0.1:3000'; then
    log "Backend is listening on 127.0.0.1:3000"
else
    die "Backend is not listening on 127.0.0.1:3000"
fi

if ss -ltn | grep -qE '0.0.0.0:80|\\[::\\]:80'; then
    log "Nginx is listening on port 80"
else
    die "Nginx is not listening on port 80"
fi

log "Checking application health"

HEALTH_RESPONSE="$(curl -fsS http://127.0.0.1/health)"

if echo "$HEALTH_RESPONSE" | grep -q '"status":"healthy"'; then
    log "Application health check passed"
else
    log "Health response: $HEALTH_RESPONSE"
    die "Application health check failed"
fi

log "Checking DNS resolution"

if getent hosts example.com >/dev/null 2>&1; then
    log "DNS resolution is working"
else
    die "DNS resolution failed"
fi

log "Checking UFW firewall"

if ufw status | grep -q "Status: active"; then
    log "UFW is active"
else
    die "UFW is not active"
fi

if ufw status | grep -qE '22/tcp[[:space:]]+ALLOW'; then
    log "SSH firewall rule is present"
else
    die "SSH firewall rule is missing"
fi

if ufw status | grep -qE '80/tcp[[:space:]]+ALLOW'; then
    log "HTTP firewall rule is present"
else
    die "HTTP firewall rule is missing"
fi

log "Checking fail2ban jails"

if fail2ban-client status sshd >/dev/null 2>&1; then
    log "SSH fail2ban jail is active"
else
    die "SSH fail2ban jail is not active"
fi

if fail2ban-client status nginx-bad-request >/dev/null 2>&1; then
    log "Nginx fail2ban jail is active"
else
    die "Nginx fail2ban jail is not active"
fi

log "Checking logrotate configuration"

if logrotate -d /etc/logrotate.d/webapp >/dev/null 2>&1; then
    log "Logrotate configuration is valid"
else
    die "Logrotate configuration is invalid"
fi

log "Checking application log"

if [[ -f /var/log/webapp/app.log ]]; then
    log "Application log exists"
else
    die "Application log does not exist"
fi

log "========================================"
log "All validation checks passed"
log "========================================"
