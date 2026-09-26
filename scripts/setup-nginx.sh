#!/usr/bin/env bash

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"

source "$SCRIPT_DIR/common.sh"

require_root

SOURCE_CONFIG="$PROJECT_ROOT/nginx/webapp.conf"
NGINX_AVAILABLE="/etc/nginx/sites-available/webapp"
NGINX_ENABLED="/etc/nginx/sites-enabled/webapp"
NGINX_DEFAULT="/etc/nginx/sites-enabled/default"

log "Setting up Nginx"

require_command apt-get
require_command curl

if [[ ! -f "$SOURCE_CONFIG" ]]; then
    die "Nginx configuration not found: $SOURCE_CONFIG"
fi

if ! dpkg -s nginx >/dev/null 2>&1; then
    log "Installing Nginx"
    apt-get update
    apt-get install -y nginx
else
    log "Nginx is already installed"
fi

log "Installing Nginx configuration"

cp "$SOURCE_CONFIG" "$NGINX_AVAILABLE"
chmod 644 "$NGINX_AVAILABLE"

if [[ -L "$NGINX_ENABLED" || -e "$NGINX_ENABLED" ]]; then
    log "Nginx site is already enabled"
else
    ln -s "$NGINX_AVAILABLE" "$NGINX_ENABLED"
    log "Enabled webapp Nginx site"
fi

if [[ -e "$NGINX_DEFAULT" || -L "$NGINX_DEFAULT" ]]; then
    rm -f "$NGINX_DEFAULT"
    log "Removed default Nginx site"
fi

log "Validating Nginx configuration"

if ! nginx -t; then
    die "Nginx configuration validation failed"
fi

log "Enabling Nginx"

systemctl enable nginx

log "Restarting Nginx"

systemctl restart nginx

if ! systemctl is-active --quiet nginx; then
    systemctl status nginx --no-pager
    die "Nginx is not running"
fi

log "Testing application through HTTPS"

if ! curl -kfsS https://127.0.0.1/health >/dev/null; then
    die "Nginx HTTPS health check failed"
fi

log "Nginx configured successfully"
