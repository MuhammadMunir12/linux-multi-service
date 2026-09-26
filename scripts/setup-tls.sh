#!/usr/bin/env bash

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

source "$SCRIPT_DIR/common.sh"

require_root

CERT_DIR="/etc/nginx/ssl"
CERT_FILE="$CERT_DIR/webapp.crt"
KEY_FILE="$CERT_DIR/webapp.key"

log "Setting up self-signed TLS"

require_command openssl

if [[ ! -d "$CERT_DIR" ]]; then
    log "Creating TLS certificate directory"
    mkdir -p "$CERT_DIR"
fi

if [[ ! -f "$CERT_FILE" || ! -f "$KEY_FILE" ]]; then
    log "Generating self-signed TLS certificate"

    openssl req \
        -x509 \
        -nodes \
        -newkey rsa:2048 \
        -days 365 \
        -keyout "$KEY_FILE" \
        -out "$CERT_FILE" \
        -subj "/CN=localhost" \
        -addext "subjectAltName=DNS:localhost,IP:127.0.0.1"
else
    log "TLS certificate already exists"
fi

chmod 600 "$KEY_FILE"
chmod 644 "$CERT_FILE"

log "Self-signed TLS certificate configured"
