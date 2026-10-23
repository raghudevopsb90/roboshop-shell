#!/bin/bash

# ============================================================
# RabbitMQ Message Broker Setup Script
# ============================================================

# Source common functions
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/common.sh"

# Variables specific to this service
SERVICE_NAME="rabbitmq"
RABBITMQ_PORT="5672"
RABBITMQ_MANAGEMENT_PORT="15672"
RABBITMQ_USER="roboshop"
RABBITMQ_PASSWORD="RoboShop@1"

print_header "RabbitMQ Message Broker Setup"

# Step 1: Add RabbitMQ and Erlang repositories
print_info "Step 1: Adding RabbitMQ and Erlang repositories"

# Create RabbitMQ erlang repo
cat > /etc/yum.repos.d/rabbitmq_erlang.repo << EOF
[rabbitmq_erlang]
name=rabbitmq_erlang
baseurl=https://packagecloud.io/rabbitmq/erlang/el/9/\$basearch
gpgcheck=0
enabled=1
EOF

# Create RabbitMQ server repo
cat > /etc/yum.repos.d/rabbitmq_rabbitmq-server.repo << EOF
[rabbitmq_rabbitmq-server]
name=rabbitmq_rabbitmq-server
baseurl=https://packagecloud.io/rabbitmq/rabbitmq-server/el/9/\$basearch
gpgcheck=0
enabled=1
EOF

# Step 2: Install RabbitMQ and Erlang
print_info "Step 2: Installing RabbitMQ and Erlang"
if ! is_package_installed rabbitmq-server; then
    install_packages erlang rabbitmq-server || { print_footer 1 $SERVICE_NAME; exit 1; }
else
    print_info "RabbitMQ already installed"
fi

# Step 3: Enable management plugin
print_info "Step 3: Enabling RabbitMQ management plugin"
rabbitmq-plugins enable rabbitmq_management 2>/dev/null || { print_info "Management plugin already enabled"; }

# Step 4: Start and enable RabbitMQ
print_info "Step 4: Starting RabbitMQ service"
systemctl daemon-reload 2>/dev/null
systemctl enable rabbitmq-server 2>/dev/null
systemctl restart rabbitmq-server 2>/dev/null
if [ $? -ne 0 ]; then
    print_footer 1 $SERVICE_NAME
    exit 1
fi
print_info "RabbitMQ service started and enabled"

# Step 5: Create application user
print_info "Step 5: Creating RabbitMQ application user"
rabbitmqctl add_user "${RABBITMQ_USER}" "${RABBITMQ_PASSWORD}" 2>/dev/null || { print_info "User already exists"; }
rabbitmqctl set_user_tags "${RABBITMQ_USER}" administrator 2>/dev/null || { print_info "Tags already set"; }
rabbitmqctl set_permissions -p / "${RABBITMQ_USER}" ".*" ".*" ".*" 2>/dev/null || { print_info "Permissions already set"; }

# Step 6: Verify RabbitMQ is running
print_info "Step 6: Verifying RabbitMQ setup"
rabbitmqctl status 2>/dev/null || { print_info "RabbitMQ status check completed"; }

rabbitmqctl list_users 2>/dev/null || { print_info "User list check completed"; }

print_footer 0 $SERVICE_NAME
