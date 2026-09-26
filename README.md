# Linux Multi-Service Environment

Automated provisioning of a secure, multi-service Linux environment using Bash, systemd, Nginx, Flask, UFW, fail2ban, logrotate, cron, and self-signed TLS.

## 1. Overview

This project provisions a small production-style Linux web environment with:

* Python Flask backend
* Dedicated non-root `webapp` service user
* Python virtual environment
* systemd service management
* Nginx reverse proxy
* HTTPS with a self-signed TLS certificate
* HTTP to HTTPS redirection
* UFW firewall
* fail2ban protection for SSH and Nginx
* Application logging
* Log rotation
* Automated health monitoring
* DNS resolution checks
* Central provisioning log
* Automated validation
* Idempotent provisioning

The application is intentionally simple. The focus of the assignment is infrastructure automation, service management, security, observability, and reproducibility.

---

## 2. Architecture

```text
                    Client
                      |
                      |
                 TCP :80 / :443
                      |
                      v
              +---------------+
              |     Nginx     |
              | Reverse Proxy |
              +---------------+
                 |         |
        HTTP :80 |         | HTTPS :443
        redirect |         |
                 +----+----+
                      |
                      v
              127.0.0.1:3000
                      |
                      v
              +---------------+
              | Flask Web App |
              |   webapp user |
              +---------------+
                      |
                      v
              /var/log/webapp/
```

Security and management components:

```text
                    +----------------+
                    |      UFW       |
                    | 22 / 80 / 443 |
                    +----------------+
                            |
                            v
Client ---> Nginx ---> Flask ---> Application Logs
              |
              +----> fail2ban
              |
              +----> TLS

cron ---> monitor.sh ---> service / HTTPS / DNS checks
```

---

## 3. Network Ports

| Port | Service | Purpose                | Public |
| ---- | ------- | ---------------------- | ------ |
| 22   | SSH     | Remote administration  | Yes    |
| 80   | Nginx   | HTTP redirect to HTTPS | Yes    |
| 443  | Nginx   | HTTPS reverse proxy    | Yes    |
| 3000 | Flask   | Backend application    | No     |

The Flask backend listens only on:

```text
127.0.0.1:3000
```

It is therefore not directly exposed to the network.

---

## 4. Project Structure

```text
linux-multi-service/
├── app/
│   ├── app.py
│   └── requirements.txt
│
├── scripts/
│   ├── common.sh
│   ├── setup-backend.sh
│   ├── setup-fail2ban.sh
│   ├── setup-firewall.sh
│   ├── setup-logging.sh
│   ├── setup-monitoring.sh
│   ├── setup-nginx.sh
│   ├── setup-systemd.sh
│   ├── setup-tls.sh
│   ├── setup-user.sh
│   ├── validate.sh
│   └── monitor.sh
│
├── systemd/
│   └── webapp.service
│
├── nginx/
│   └── webapp.conf
│
├── fail2ban/
│   └── jail.local
│
├── logrotate/
│   └── webapp
│
├── cron/
│   └── linux-multi-service
│
├── .gitignore
├── README.md
└── provision.sh
```

---

## 5. Requirements

The target system is Ubuntu Linux with:

* Bash
* systemd
* Internet connectivity
* sudo/root access
* apt package manager

The provisioning scripts install required packages where appropriate.

---

## 6. Installation

Clone or copy the repository to the target Linux machine.

```bash
cd ~/linux-multi-service
```

Make scripts executable if required:

```bash
chmod +x provision.sh
chmod +x scripts/*.sh
```

Run the main provisioning script:

```bash
sudo ./provision.sh
```

The provisioning process executes the individual setup scripts in dependency order.

---

## 7. Provisioning Order

`provision.sh` performs the following steps:

```text
1. Webapp user and directories
2. Python backend
3. systemd service
4. Self-signed TLS
5. Nginx reverse proxy
6. UFW firewall
7. fail2ban protection
8. Application logging
9. Automated monitoring
10. Environment validation
```

Each component is implemented as a separate script instead of putting the entire environment into one large Bash script.

---

## 8. Backend

The backend is a small Flask application.

It runs as:

```text
User: webapp
Group: webapp
Working directory: /opt/webapp/app
Python environment: /opt/webapp/venv
Address: 127.0.0.1:3000
```

The application provides two endpoints.

### Root endpoint

```text
/
```

Example:

```bash
curl -k https://127.0.0.1/
```

### Health endpoint

```text
/health
```

Example:

```bash
curl -k https://127.0.0.1/health
```

Expected response:

```json
{
  "status": "healthy",
  "service": "webapp"
}
```

The `-k` option is required because the environment uses a self-signed certificate.

---

## 9. Dedicated Service User

The application runs as the non-root system user:

```text
webapp
```

The user has:

* No interactive shell
* Ownership of application files
* Ownership of application logs
* No requirement for root privileges

Application files are installed under:

```text
/opt/webapp/
```

Application logs are stored under:

```text
/var/log/webapp/
```

This separates application privileges from system administration privileges.

---

## 10. systemd

The backend is managed by:

```text
webapp.service
```

The service:

* Starts automatically at boot
* Runs as `webapp`
* Restarts if the process fails
* Uses the Python virtual environment
* Listens on `127.0.0.1:3000`

Check the service:

```bash
sudo systemctl status webapp
```

Restart:

```bash
sudo systemctl restart webapp
```

View logs:

```bash
sudo journalctl -u webapp
```

---

## 11. Nginx

Nginx acts as the reverse proxy.

HTTP requests are redirected:

```text
HTTP :80
    |
    v
HTTPS :443
```

HTTPS requests are forwarded to:

```text
127.0.0.1:3000
```

Nginx forwards the following headers:

```text
Host
X-Real-IP
X-Forwarded-For
X-Forwarded-Proto
```
Check configuration:

sudo nginx -t

Restart:

sudo systemctl restart nginx
12. TLS

The project implements the TLS bonus using a self-signed certificate.

Certificates are generated at:

/etc/nginx/ssl/webapp.crt
/etc/nginx/ssl/webapp.key

The certificate includes:

DNS:localhost
IP:127.0.0.1

TLS protocols enabled:

TLSv1.2
TLSv1.3

Because the certificate is self-signed, browsers and clients will not automatically trust it.

For local testing:

curl -k https://127.0.0.1/health

This is suitable for an assignment/development environment. A production deployment should use a certificate issued by a trusted Certificate Authority.

13. Firewall

UFW is configured with a default-deny incoming policy.

Allowed ports:

22/tcp
80/tcp
443/tcp

The backend port 3000 is intentionally not opened.

Check firewall status:

sudo ufw status verbose

Expected application exposure:

Internet
   |
   +-- 22  SSH
   +-- 80  HTTP
   +-- 443 HTTPS
   |
   X-- 3000 Flask backend
14. fail2ban

fail2ban protects:

SSH
Nginx bad requests

Configured jails:

sshd
nginx-bad-request

Check status:

sudo fail2ban-client status

Check SSH jail:

sudo fail2ban-client status sshd

Check Nginx jail:

sudo fail2ban-client status nginx-bad-request

Configuration validation:

sudo fail2ban-client -t
15. Application Logging

The Flask application writes logs to:

/var/log/webapp/app.log

The application records information such as:

Request method
Request path
Remote address
Health check requests

Example:

sudo tail -f /var/log/webapp/app.log

The application log is owned by the webapp service account.

16. Log Rotation

Application logs are managed by logrotate.

Configuration:

/etc/logrotate.d/webapp

Current policy:

Daily rotation
7 rotated files
Compression enabled
Missing files ignored
Empty files skipped
copytruncate enabled

Test the configuration:

sudo logrotate -d /etc/logrotate.d/webapp

Force a rotation for testing:

sudo logrotate -f /etc/logrotate.d/webapp
17. Automated Monitoring

The project includes a lightweight monitoring mechanism using cron.

Cron runs:

every 5 minutes

Configuration:

/etc/cron.d/linux-multi-service

The monitoring script checks:

webapp service
Nginx service
fail2ban service
HTTPS application health
DNS resolution

Script:

scripts/monitor.sh

The monitoring result is written to:

/var/log/linux-multi-service/provision.log

The monitoring command can also be executed manually:

sudo ./scripts/monitor.sh
18. Validation

The project includes a dedicated validation script:

sudo ./scripts/validate.sh

Validation covers:

Required services
Backend listening port
Nginx HTTP port
Nginx HTTPS port
HTTPS application health
DNS resolution
UFW status
SSH firewall rule
HTTP firewall rule
HTTPS firewall rule
SSH fail2ban jail
Nginx fail2ban jail
logrotate configuration
application log existence

Successful validation ends with:

All validation checks passed
19. Provisioning Logs

Provisioning activity is logged to:

/var/log/linux-multi-service/provision.log

The log contains timestamped entries for each provisioning step.

Example:

[2026-09-26 22:00:00] Starting: Nginx reverse proxy
[2026-09-26 22:00:01] Nginx configuration validated
[2026-09-26 22:00:01] Nginx configured successfully

This provides a simple audit trail for automation failures and troubleshooting.

20. Idempotency

The provisioning scripts are designed to be safely executed multiple times.

Examples:

Existing users are detected
Existing directories are reused
Existing Python virtual environments are reused
Existing packages are detected
Existing Nginx sites are reused
Existing firewall rules are checked before adding them
Existing TLS certificates are reused
Existing cron configuration is replaced with the repository version
Existing systemd configuration is updated and restarted
Configuration files are validated before services are restarted

The recommended test is:

sudo ./provision.sh
sudo ./provision.sh

The second execution should complete successfully without creating duplicate configuration.

21. Error Handling

The automation uses:

set -euo pipefail

Scripts use common helper functions for:

Root validation
Required command validation
Timestamped logging
Meaningful errors
Shared provisioning log

Example:

die "Nginx configuration validation failed"

This causes the provisioning process to stop instead of continuing with a partially configured environment.

22. Design Decisions
Modular scripts

Each major component has its own script.

This makes the environment easier to:

Understand
Test
Troubleshoot
Modify
Reuse
Non-root application

The Flask service does not run as root.

This reduces the impact of a potential application compromise.

Local backend binding

The application listens on:

127.0.0.1:3000

Only Nginx is exposed to external clients.

Reverse proxy

Nginx provides:

TLS termination
HTTP to HTTPS redirection
Client IP forwarding
A single external entry point
Validation

Validation is separated from provisioning so the environment can be checked independently.

Configuration as code

Nginx, systemd, fail2ban, logrotate, and cron configurations are stored in the repository.

This allows the environment to be reproduced from source control.

23. Troubleshooting
Check all services
sudo systemctl status webapp
sudo systemctl status nginx
sudo systemctl status fail2ban
Check listening ports
sudo ss -ltnp

Expected relevant ports:

127.0.0.1:3000
0.0.0.0:80
0.0.0.0:443
Test backend directly
curl http://127.0.0.1:3000/health
Test HTTPS
curl -k https://127.0.0.1/health
Check Nginx configuration
sudo nginx -t
Check Nginx logs
sudo tail -f /var/log/nginx/error.log
sudo tail -f /var/log/nginx/access.log
Check application logs
sudo tail -f /var/log/webapp/app.log
Check provisioning logs
sudo tail -f /var/log/linux-multi-service/provision.log
Check firewall
sudo ufw status verbose
Check fail2ban
sudo fail2ban-client status
24. Security Considerations

This project implements several basic security controls:

Non-root application user
Backend bound to localhost
Default-deny UFW incoming policy
Only required network ports exposed
SSH and Nginx fail2ban protection
TLS encryption
Restricted private key permissions
Application log permissions
systemd service isolation through a dedicated account

The TLS certificate is self-signed and therefore should not be considered production-grade certificate management.

A production deployment should additionally consider:

Trusted CA certificates
Automated certificate renewal
SSH key-only authentication
Stronger systemd sandboxing
Secrets management
Centralized logging
Metrics and alerting
Automated security updates
Container or VM hardening
Backup and disaster recovery
25. Assignment Requirements Coverage
Requirement	Implementation
Main provision.sh	Implemented
Individual service scripts	Implemented
set -euo pipefail	Implemented
Idempotent provisioning	Implemented
Timestamped provisioning log	Implemented
Input/command validation	Implemented
Modular functions/scripts	Implemented
Nginx reverse proxy	Implemented
Backend on port 3000	Implemented
UFW firewall	Implemented
fail2ban SSH protection	Implemented
fail2ban Nginx protection	Implemented
Non-root service user	Implemented
systemd service	Implemented
Application logging	Implemented
logrotate	Implemented
Nginx forwarding headers	Implemented
Health endpoint	Implemented
DNS verification	Implemented
Self-signed TLS	Implemented
Automated monitoring	Implemented


26. Final Verification

Run:

sudo ./provision.sh

Run provisioning a second time:

sudo ./provision.sh

Then:

sudo ./scripts/validate.sh

Expected final result:

All validation checks passed

Check the repository:

git status
