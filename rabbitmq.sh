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

echo -e "\\e[36mAdding RabbitMQ and Erlang repositories\\e[0m"

# Create RabbitMQ erlang repo
cat > /etc/yum.repos.d/rabbitmq_erlang.repo << EOF
[rabbitmq_erlang]
name=rabbitmq_erlang
baseurl=https://packagecloud.io/rabbitmq/erlang/el/9/\$basearch
gpgcheck=0
enabled=1
EOF
echo $?

# Create RabbitMQ server repo
cat > /etc/yum.repos.d/rabbitmq_rabbitmq-server.repo << EOF
[rabbitmq_rabbitmq-server]
name=rabbitmq_rabbitmq-server
baseurl=https://packagecloud.io/rabbitmq/rabbitmq-server/el/9/\$basearch
gpgcheck=0
enabled=1
EOF
echo $?

echo -e "\\e[36mInstalling RabbitMQ and Erlang\\e[0m"
dnf install -y erlang rabbitmq-server &>>$LOG_FILE
echo $?

echo -e "\\e[36mEnabling RabbitMQ management plugin\\e[0m"
rabbitmq-plugins enable rabbitmq_management &>>$LOG_FILE
echo $?

echo -e "\\e[36mStarting RabbitMQ service\\e[0m"
systemctl daemon-reload &>>$LOG_FILE
systemctl enable rabbitmq-server &>>$LOG_FILE
systemctl restart rabbitmq-server &>>$LOG_FILE
echo $?

echo -e "\\e[36mCreating RabbitMQ application user\\e[0m"
rabbitmqctl add_user "${RABBITMQ_USER}" "${RABBITMQ_PASSWORD}" &>>$LOG_FILE
rabbitmqctl set_user_tags "${RABBITMQ_USER}" administrator &>>$LOG_FILE
rabbitmqctl set_permissions -p / "${RABBITMQ_USER}" ".*" ".*" ".*" &>>$LOG_FILE
echo $?

print_footer 0 $SERVICE_NAME
