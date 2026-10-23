# RoboShop Shell Scripts - Deployment Guide

## Overview

This directory contains shell scripts for deploying the RoboShop microservices architecture. All scripts are idempotent, follow DRY principles, and use log redirection to capture output while only showing exit status.

## Files Structure

| File | Purpose |
|------|---------|
| `common.sh` | Shared variables and functions for all services |
| `frontend.sh` | Nginx + Frontend setup |
| `mysql.sh` | MySQL database setup |
| `catalogue.sh` | Go Catalogue service |
| `mongodb.sh` | MongoDB database setup |
| `user.sh` | Node.js User service |
| `valkey.sh` | Valkey database setup |
| `cart.sh` | Node.js Cart service |
| `shipping.sh` | Java Shipping service |
| `rabbitmq.sh` | RabbitMQ message broker setup |
| `payment.sh` | Python Payment service |
| `notification.sh` | Python Notification service |
| `orders.sh` | Java Orders service |
| `ratings.sh` | Python Ratings service |

## Pre-requisites

- RHEL 10 operating system
- Internet access for package downloads
- Appropriate firewall/security group rules
- DNS records for `rdevopsb90.online` pointing to respective servers

## Setup Order

Follow this order to ensure all dependencies are met:

### 1. Database Servers (Run once per server)
```
mysql.sh           # Server 2: MySQL database
mongodb.sh         # Server 4: MongoDB database
valkey.sh          # Server 6: Valkey cache
rabbitmq.sh        # Server 9: RabbitMQ broker
```

### 2. Application Services (Run once per server)
```
frontend.sh        # Server 1: Nginx + Frontend
catalogue.sh       # Server 3: Go Catalogue service
user.sh            # Server 5: Node.js User service
cart.sh            # Server 7: Node.js Cart service
shipping.sh        # Server 8: Java Shipping service
payment.sh         # Server 10: Python Payment service
notification.sh    # Server 11: Python Notification service
orders.sh          # Server 12: Java Orders service
ratings.sh         # Server 13: Python Ratings service
```

## Service Dependencies

```
Frontend → All backend services

Catalogue → MySQL
Shipping → MySQL
Ratings → MySQL

User → MongoDB
Cart → Valkey, Catalogue

Payment → RabbitMQ, Cart, User
Orders → MongoDB, RabbitMQ, Shipping, Notification
Notification → RabbitMQ
```

## Configuration

### DNS Configuration

All services use DNS-based communication with domain: `rdevopsb90.online`

| Service | DNS Endpoint |
|---------|-------------|
| MySQL | mysql.rdevopsb90.online |
| MongoDB | mongodb.rdevopsb90.online |
| Valkey | valkey.rdevopsb90.online |
| RabbitMQ | rabbitmq.rdevopsb90.online |
| Catalogue | catalogue.rdevopsb90.online |
| User | user.rdevopsb90.online |
| Cart | cart.rdevopsb90.online |
| Shipping | shipping.rdevopsb90.online |
| Ratings | ratings.rdevopsb90.online |
| Orders | orders.rdevopsb90.online |
| Notification | notification.rdevopsb90.online |

### Ports

| Service | Port |
|---------|------|
| Frontend (Nginx) | 80 |
| Frontend (Node.js internal) | 3000 |
| User | 8001 |
| Catalogue | 8002 |
| Cart | 8003 |
| Shipping | 8004 |
| Payment | 8005 |
| Ratings | 8006 |
| Orders | 8007 |
| Notification | 8008 |
| MySQL | 3306 |
| MongoDB | 27017 |
| Valkey | 6379 |
| RabbitMQ | 5672 |
| RabbitMQ Management | 15672 |

### Default Passwords

All passwords are defined in `common.sh`:
- MySQL Root: `RoboShop@1`
- MongoDB: `RoboShop@1`
- Valkey: (N/A)
- RabbitMQ: `RoboShop@1`

## Running Scripts

Each script can be run with:
```bash
./script-name.sh
```

Each script will:
1. Print a header showing the service being set up
2. Execute each step with a colored message
3. Shows only the exit status (0=success, 1=failure)
4. Logs full output to `/tmp/roboshop.log`
5. Print a footer with SUCCESS or FAILURE status

### For re-runs

All scripts are idempotent and can be re-run without failure:
- Checks for existing installations before installing
- Uses `IF NOT EXISTS` patterns for database operations
- Gracefully handles already configured services

## Script Output

The scripts use the following pattern for command execution:

```bash
echo -e "\\e[36mStep Description\\e[0m"
command &>>$LOG_FILE
echo $?
```

Where:
- `\\e[36m` = Cyan text color (for step description)
- `&>>$LOG_FILE` = Redirects output to `/tmp/roboshop.log`
- `echo $?` = Prints exit status (0 for success, non-zero for failure)

## Troubleshooting

### Check Service Status
```bash
systemctl status <service-name>
journalctl -u <service-name> -f
```

### View Logs
- Application logs: `journalctl -u <service-name> -f`
- Installation logs: `cat /tmp/roboshop.log`
- Nginx: `/var/log/nginx/`
- MySQL: `/var/log/mysql/`
- MongoDB: `/var/log/mongodb/`

### Restart Service
```bash
systemctl restart <service-name>
```

## Notes

- All scripts use the `roboshop` user for running applications
- Services are started with systemd
- DNS resolution must work for all service-to-service communication
- Passwords are hardcoded for simplicity (can be externalized later)
- Log files are cleared at the start of each script execution
- Use colored output for better visibility during execution
