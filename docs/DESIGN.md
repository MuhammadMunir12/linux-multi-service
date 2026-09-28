# Design Document

## 1. Purpose

This project provides a small production-style Linux web environment with automated provisioning, service management, security controls, logging, monitoring, and validation.

The application itself is intentionally simple. The main focus is the infrastructure and deployment design.

## 2. High-Level Architecture

```text
                    Client
                      |
               +------+------+
               |             |
             HTTP           HTTPS
              :80            :443
               |             |
               +------+------+
                      |
                    Nginx
                      |
               Reverse Proxy
                      |
                      v
               127.0.0.1:3000
                      |
                    Flask
                      |
                   webapp
```

Supporting infrastructure:

```text
             +-------------------+
             |       UFW         |
             | 22 / 80 / 443    |
             +-------------------+

             +-------------------+
             |     fail2ban      |
             | SSH + Nginx      |
             +-------------------+

             +-------------------+
             |      systemd      |
             |   webapp.service  |
             +-------------------+

             +-------------------+
             |      cron         |
             |  health monitor   |
             +-------------------+
```

## 3. Application

The backend is a Python Flask application.

It exposes:

```text
GET /
GET /health
```

The health endpoint returns:

```json
{
  "status": "healthy",
  "service": "webapp"
}
```

The application listens only on:

```text
127.0.0.1:3000
```

This prevents direct external access to the backend.

## 4. Reverse Proxy

Nginx is the external entry point.

HTTP traffic:

```text
Client → :80 → HTTPS redirect
```

HTTPS traffic:

```text
Client → :443 → Nginx → 127.0.0.1:3000
```

Nginx forwards:

```text
Host
X-Real-IP
X-Forwarded-For
X-Forwarded-Proto
```

This preserves useful client/request information for the backend.

## 5. TLS

The project generates a self-signed certificate during deployment.

Certificate:

```text
/etc/nginx/ssl/webapp.crt
```

Private key:

```text
/etc/nginx/ssl/webapp.key
```

TLS protocols:

```text
TLSv1.2
TLSv1.3
```

The certificate is suitable for local development and assignment testing, not production public use.

## 6. Process Management

The Flask application runs under systemd:

```text
webapp.service
```

Configuration:

```text
User=webapp
Group=webapp
Restart=on-failure
```

The application therefore:

* Does not run as root
* Starts automatically at boot
* Restarts after failures
* Has a predictable service lifecycle

## 7. Security Design

### Non-root execution

The application runs as:

```text
webapp
```

The account uses:

```text
/usr/sbin/nologin
```

### Firewall

UFW uses a default-deny incoming policy.

Allowed:

```text
22/tcp
80/tcp
443/tcp
```

Port 3000 is not exposed externally.

### fail2ban

Two jails are configured:

```text
sshd
nginx-bad-request
```

This provides basic automated blocking for repeated suspicious activity.

## 8. Logging

Application logs:

```text
/var/log/webapp/app.log
```

Provisioning logs:

```text
/var/log/linux-multi-service/provision.log
```

Logrotate manages application log retention.

Current policy:

```text
Daily rotation
7 rotations
Compression
copytruncate
```

## 9. Monitoring

A cron job runs the monitoring script every five minutes.

It checks:

* webapp service
* Nginx
* fail2ban
* HTTPS health endpoint
* DNS resolution

Monitoring results are written to the provisioning log.

## 10. Automation Design

The main entry point is:

```text
provision.sh
```

It calls smaller component-specific scripts.

```text
provision.sh
    |
    +-- setup-user.sh
    +-- setup-backend.sh
    +-- setup-systemd.sh
    +-- setup-tls.sh
    +-- setup-nginx.sh
    +-- setup-firewall.sh
    +-- setup-fail2ban.sh
    +-- setup-logging.sh
    +-- setup-monitoring.sh
    +-- validate.sh
```

This keeps the automation modular instead of creating one large script.

## 11. Idempotency

The scripts check existing state before creating resources.

Examples:

* Existing users are reused
* Existing directories are reused
* Existing virtual environments are reused
* Existing packages are detected
* Existing firewall rules are checked
* Existing certificates are reused
* Existing services are restarted safely
* Configuration files are replaced with the repository version

The expected behavior is that running:

```bash
sudo ./provision.sh
sudo ./provision.sh
```

does not create duplicate resources or fail because the environment already exists.

## 12. Validation

`validate.sh` verifies the deployed environment.

It checks:

* Required services
* Backend port
* HTTP port
* HTTPS port
* HTTPS health endpoint
* DNS
* UFW
* Firewall rules
* fail2ban jails
* logrotate
* application logs

Successful deployment should end with:

```text
All validation checks passed
```

## 13. Design Trade-offs

### Flask

Flask was selected because the application requirement is simple and it keeps the focus on infrastructure rather than application complexity.

### Nginx

Nginx provides a single external entry point and handles TLS termination and reverse proxying.

### systemd

systemd is native to the target Linux environment and provides reliable process lifecycle management.

### Self-signed TLS

Self-signed TLS provides an easy way to demonstrate encrypted HTTPS without requiring a public domain or external Certificate Authority.

### Cron monitoring

Cron provides a lightweight monitoring mechanism without introducing a full monitoring stack.

## 14. Future Improvements

For production use, the following could be added:

* Trusted CA certificates
* Automatic certificate renewal
* Prometheus/Grafana metrics
* Centralized logging
* Secrets management
* Automated backups
* Systemd sandboxing
* Automated security updates
* CI/CD pipeline
* Infrastructure-as-Code tooling
