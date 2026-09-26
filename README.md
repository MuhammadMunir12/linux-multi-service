# Linux Multi-Service Environment

Automated provisioning of a secure multi-service Linux environment using Bash, Python Flask, Nginx, systemd, UFW, Fail2ban, and logrotate.

## Overview

This project provisions a Linux server with:

- Python Flask backend
- Nginx reverse proxy
- systemd service management
- Dedicated non-root `webapp` service user
- UFW firewall
- Fail2ban protection for SSH and Nginx
- Application logging
- Log rotation
- Health checks
- DNS resolution verification
- Idempotent provisioning
- Timestamped provisioning logs

The environment is designed so that the backend is not directly exposed to the network. Nginx provides the public HTTP entry point and forwards requests to the Flask application on localhost.

## Architecture

```text
                         Client
                           |
                           | HTTP :80
                           v
                  +-------------------+
                  |       Nginx       |
                  | Reverse Proxy     |
                  +---------+---------+
                            |
                            | 127.0.0.1:3000
                            v
                  +-------------------+
                  |   Flask Backend   |
                  |     webapp user   |
                  +---------+---------+
                            |
                            v
                  /var/log/webapp/app.log


Security Layer:

    Internet
       |
       v
      UFW
       |
       +---- SSH :22
       |
       +---- HTTP :80
       |
       +---- Backend :3000
             NOT publicly exposed

    Fail2ban
       |
       +---- SSH protection
       +---- Nginx protection
