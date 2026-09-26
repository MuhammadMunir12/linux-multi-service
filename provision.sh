#!/usr/bin/env bash

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

LOG_DIR="/var/log/linux-multi-service"
LOG_FILE="$LOG_DIR/provision.log"

mkdir -p "$LOG_DIR"
touch "$LOG_FILE"
chmod 640 "$LOG_FILE"

log() {
    local message="$1"
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] $message" | tee -a "$LOG_FILE"
}

die() {
    local message="$1"
    echo "ERROR: $message" | tee -a "$LOG_FILE" >&2
    exit 1
}

require_root() {
    if [[ "${EUID}" -ne 0 ]]; then
        die "This script must be run as root. Use: sudo ./provision.sh"
    fi
}

run_step() {
    local script="$1"
    local description="$2"

    log "========================================"
    log "Starting: $description"
    log "========================================"

    if [[ ! -f "$SCRIPT_DIR/scripts/$script" ]]; then
        die "Script not found: $SCRIPT_DIR/scripts/$script"
    fi

    if ! bash "$SCRIPT_DIR/scripts/$script"; then
        die "Failed: $description"
    fi

    log "Completed: $description"
}

require_root

log "========================================"
log "Linux Multi-Service Environment"
log "Provisioning started"
log "========================================"

run_step "setup-user.sh" "Webapp user and directories"
run_step "setup-backend.sh" "Python backend"
run_step "setup-systemd.sh" "Systemd service"
run_step "setup-tls.sh" "Self-signed TLS"
run_step "setup-nginx.sh" "Nginx reverse proxy"
run_step "setup-firewall.sh" "UFW firewall"
run_step "setup-fail2ban.sh" "Fail2ban protection"
run_step "setup-logging.sh" "Application logging"
run_step "setup-monitoring.sh" "Automated monitoring"
run_step "validate.sh" "Environment validation"

log "========================================"
log "Provisioning completed successfully"
log "========================================"
