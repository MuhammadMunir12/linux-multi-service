#!/usr/bin/env bash

set -euo pipefail

LOG_DIR="/var/log/linux-multi-service"
LOG_FILE="$LOG_DIR/provision.log"

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
        die "This script must be run as root. Use sudo."
    fi
}

require_command() {
    local command_name="$1"

    if ! command -v "$command_name" >/dev/null 2>&1; then
        die "Required command not found: $command_name"
    fi
}

ensure_log_dir() {
    mkdir -p "$LOG_DIR"
    touch "$LOG_FILE"
    chmod 640 "$LOG_FILE"
}
