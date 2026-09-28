# Deployment Guide

## 1. Prerequisites

Target environment:

* Ubuntu Linux
* sudo/root access
* Internet connectivity
* Git
* systemd
* apt

Clone the repository:

```bash
git clone https://github.com/<username>/linux-multi-service.git
cd linux-multi-service
```

Make scripts executable:

```bash
chmod +x provision.sh
chmod +x scripts/*.sh
```

---

# 2. Manual Deployment

The manual process is useful for understanding what the automation does.

## Step 1: Create the service user

```bash
sudo useradd \
  --system \
  --create-home \
  --shell /usr/sbin/nologin \
  webapp
```

Create directories:

```bash
sudo mkdir -p \
  /opt/webapp/app \
  /opt/webapp/logs \
  /opt/webapp/config \
  /var/log/webapp
```

Set ownership:

```bash
sudo chown -R webapp:webapp /opt/webapp
sudo chown webapp:webapp /var/log/webapp
```

---

## Step 2: Install Python

```bash
sudo apt update
sudo apt install -y python3 python3-venv
```

Copy the application:

```bash
sudo cp app/app.py /opt/webapp/app/
sudo cp app/requirements.txt /opt/webapp/app/
```

Create the virtual environment:

```bash
sudo -u webapp python3 -m venv /opt/webapp/venv
```

Install dependencies:

```bash
sudo -u webapp \
  /opt/webapp/venv/bin/pip install \
  -r /opt/webapp/app/requirements.txt
```

---

## Step 3: Configure Logging

Create the application log:

```bash
sudo touch /var/log/webapp/app.log
sudo chown webapp:webapp /var/log/webapp/app.log
sudo chmod 640 /var/log/webapp/app.log
```

Install logrotate:

```bash
sudo cp logrotate/webapp /etc/logrotate.d/webapp
```

Test:

```bash
sudo logrotate -d /etc/logrotate.d/webapp
```

---

## Step 4: Configure systemd

Copy the service:

```bash
sudo cp systemd/webapp.service /etc/systemd/system/webapp.service
```

Reload systemd:

```bash
sudo systemctl daemon-reload
```

Enable and start:

```bash
sudo systemctl enable --now webapp
```

Check:

```bash
sudo systemctl status webapp
```

Verify the backend:

```bash
curl http://127.0.0.1:3000/health
```

---

## Step 5: Install Nginx

```bash
sudo apt update
sudo apt install -y nginx
```

Copy the configuration:

```bash
sudo cp nginx/webapp.conf /etc/nginx/sites-available/webapp
```

Enable it:

```bash
sudo ln -sf \
  /etc/nginx/sites-available/webapp \
  /etc/nginx/sites-enabled/webapp
```

Remove the default site:

```bash
sudo rm -f /etc/nginx/sites-enabled/default
```

Test:

```bash
sudo nginx -t
```

---

## Step 6: Configure TLS

Create the certificate directory:

```bash
sudo mkdir -p /etc/nginx/ssl
```

Generate the certificate:

```bash
sudo openssl req \
  -x509 \
  -nodes \
  -newkey rsa:2048 \
  -days 365 \
  -keyout /etc/nginx/ssl/webapp.key \
  -out /etc/nginx/ssl/webapp.crt \
  -subj "/CN=localhost" \
  -addext "subjectAltName=DNS:localhost,IP:127.0.0.1"
```

Secure the private key:

```bash
sudo chmod 600 /etc/nginx/ssl/webapp.key
sudo chmod 644 /etc/nginx/ssl/webapp.crt
```

Restart Nginx:

```bash
sudo systemctl restart nginx
```

Test:

```bash
curl -k https://127.0.0.1/health
```

---

## Step 7: Configure UFW

Install:

```bash
sudo apt install -y ufw
```

Set defaults:

```bash
sudo ufw default deny incoming
sudo ufw default allow outgoing
```

Allow required ports:

```bash
sudo ufw allow 22/tcp
sudo ufw allow 80/tcp
sudo ufw allow 443/tcp
```

Enable:

```bash
sudo ufw --force enable
```

Check:

```bash
sudo ufw status verbose
```

Do not expose port 3000.

---

## Step 8: Configure fail2ban

Install:

```bash
sudo apt install -y fail2ban
```

Copy configuration:

```bash
sudo cp fail2ban/jail.local /etc/fail2ban/jail.local
```

Validate:

```bash
sudo fail2ban-client -t
```

Enable:

```bash
sudo systemctl enable --now fail2ban
```

Check:

```bash
sudo fail2ban-client status
```

---

## Step 9: Configure Monitoring

Install cron:

```bash
sudo apt install -y cron
```

Copy the cron configuration:

```bash
sudo cp cron/linux-multi-service /etc/cron.d/linux-multi-service
```

Set permissions:

```bash
sudo chmod 644 /etc/cron.d/linux-multi-service
```

Enable cron:

```bash
sudo systemctl enable --now cron
```

Test monitoring manually:

```bash
sudo ./scripts/monitor.sh
```

---

## Step 10: Validate Manual Deployment

Run:

```bash
sudo ./scripts/validate.sh
```

Expected:

```text
All validation checks passed
```

---

# 3. Automated Deployment

The recommended deployment method is the main provisioning script.

From the repository root:

```bash
cd linux-multi-service
```

Make scripts executable:

```bash
chmod +x provision.sh
chmod +x scripts/*.sh
```

Run:

```bash
sudo ./provision.sh
```

The script performs:

```text
setup-user
    ↓
setup-backend
    ↓
setup-systemd
    ↓
setup-tls
    ↓
setup-nginx
    ↓
setup-firewall
    ↓
setup-fail2ban
    ↓
setup-logging
    ↓
setup-monitoring
    ↓
validate
```

---

# 4. Verify Automated Deployment

Check services:

```bash
sudo systemctl status webapp
sudo systemctl status nginx
sudo systemctl status fail2ban
```

Check ports:

```bash
sudo ss -ltnp | grep -E ':(80|443)\b'
```

Expected:

```text
0.0.0.0:80
0.0.0.0:443
```

The backend should listen on:

```text
127.0.0.1:3000
```

Test HTTPS:

```bash
curl -k https://127.0.0.1/health
```

Validate:

```bash
sudo ./scripts/validate.sh
```

---

# 5. Test Idempotency

Run provisioning a second time:

```bash
sudo ./provision.sh
```

The second execution should complete successfully.

Then validate again:

```bash
sudo ./scripts/validate.sh
```

This confirms that existing resources and configuration are handled safely.

---

# 6. Useful Operations

## Restart application

```bash
sudo systemctl restart webapp
```

## Restart Nginx

```bash
sudo systemctl restart nginx
```

## View application logs

```bash
sudo tail -f /var/log/webapp/app.log
```

## View provisioning logs

```bash
sudo tail -f /var/log/linux-multi-service/provision.log
```

## View systemd logs

```bash
sudo journalctl -u webapp -f
```

## Check fail2ban

```bash
sudo fail2ban-client status
```

## Check firewall

```bash
sudo ufw status verbose
```

## Run monitoring manually

```bash
sudo ./scripts/monitor.sh
```

---

# 7. Troubleshooting

### Nginx is not starting

```bash
sudo nginx -t
sudo systemctl status nginx
```

### Backend is not running

```bash
sudo systemctl status webapp
sudo journalctl -u webapp --no-pager
```

### HTTPS is unavailable

Check:

```bash
sudo ss -ltnp | grep ':443'
```

Check certificates:

```bash
sudo ls -la /etc/nginx/ssl/
```

Check Nginx:

```bash
sudo nginx -t
```

### Firewall blocks HTTPS

```bash
sudo ufw status
```

Ensure:

```text
443/tcp ALLOW
```

### fail2ban is not running

```bash
sudo systemctl status fail2ban
sudo fail2ban-client -t
sudo fail2ban-client status
```

---

# 8. Deployment Result

A successful deployment provides:

```text
Internet
   |
   +-- TCP 80
   |      |
   |      +--> HTTPS redirect
   |
   +-- TCP 443
          |
          v
        Nginx
          |
          v
   127.0.0.1:3000
          |
          v
        Flask
```

With:

```text
systemd      → application lifecycle
UFW          → network firewall
fail2ban     → intrusion protection
logrotate    → log management
cron         → monitoring
validate.sh  → deployment verification
```
