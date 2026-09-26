#!/usr/bin/env bash

set -euo pipefail

LOG_FILE="/var/log/linux-multi-service/provision.log"

log() {
    local message="$1"
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] $message" | tee -a "$LOG_FILE"
}

failed=0

log "Starting service monitoring check"

for service in webapp nginx fail2ban; do
    if systemctl is-active --quiet "$service"; then
        log "$service: OK"
    else
        log "$service: FAILED"
        failed=1
    fi
done

if curl -kfsS https://127.0.0.1/health >/dev/null 2>&1; then
    log "HTTPS health check: OK"
else
    log "HTTPS health check: FAILED"
    failed=1
fi

if getent hosts example.com >/dev/null 2>&1; then
    log "DNS resolution: OK"
else
    log "DNS resolution: FAILED"
    failed=1
fi

if [[ "$failed" -eq 0 ]]; then
    log "Monitoring check passed"
    exit 0
else
    log "Monitoring check failed"
    exit 1
fi
