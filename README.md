# Linux Multi-Service Environment

A modular Bash-based automation project for deploying a small, secure Linux web environment.

## Architecture

```text
Client
  |
  | HTTP :80 / HTTPS :443
  v
Nginx
  |
  | Reverse Proxy
  v
Flask :3000
  |
  v
webapp (non-root user)
```

Supporting services:

* systemd for application management
* UFW for firewall
* fail2ban for SSH and Nginx protection
* logrotate for application logs
* cron-based health monitoring
* self-signed TLS for HTTPS

## Features

* Modular provisioning scripts
* Idempotent installation
* Flask backend
* Nginx reverse proxy
* HTTP to HTTPS redirect
* TLS 1.2/1.3
* Non-root application user
* UFW firewall
* fail2ban
* Application logging and rotation
* Automated monitoring
* DNS and health validation
* Timestamped provisioning logs

## Repository Structure

```text
linux-multi-service/
├── app/                  # Flask application
├── scripts/              # Provisioning and validation scripts
├── systemd/              # systemd service
├── nginx/                # Nginx configuration
├── fail2ban/             # fail2ban configuration
├── logrotate/            # Log rotation configuration
├── cron/                 # Monitoring schedule
├── docs/
│   ├── DESIGN.md         # Application and infrastructure design
│   └── DEPLOYMENT.md     # Manual and automated deployment
├── provision.sh          # Main automated provisioning
└── README.md
```

## Quick Start

### Automated

```bash
chmod +x provision.sh scripts/*.sh
sudo ./provision.sh
```

Validate:

```bash
sudo ./scripts/validate.sh
```

Run provisioning again to verify idempotency:

```bash
sudo ./provision.sh
```

### Test Application

```bash
curl -k https://127.0.0.1/health
```

Expected:

```json
{"service":"webapp","status":"healthy"}
```

## Ports

| Port | Purpose                       |
| ---- | ----------------------------- |
| 22   | SSH                           |
| 80   | HTTP → HTTPS redirect         |
| 443  | HTTPS                         |
| 3000 | Flask backend, localhost only |

## Documentation

* [Design Document](docs/DESIGN.md)
* [Deployment Guide](docs/DEPLOYMENT.md)

## Security Note

The included TLS certificate is self-signed and intended for development/assignment use. Production deployments should use a certificate issued by a trusted Certificate Authority.

## License

This project is provided for educational and assignment purposes.
