#!/bin/bash

# ============================================================
# Valkey Database Setup Script
# ============================================================

# Source common functions
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/common.sh"

# Variables specific to this service
SERVICE_NAME="valkey"
VALKEY_PORT="6379"

print_header "Valkey Database Setup"

echo -e "\\e[36mInstalling Valkey\\e[0m"
dnf install -y valkey &>>$LOG_FILE
echo $?

echo -e "\\e[36mConfiguring Valkey\\e[0m"
sed -i 's/^bind .*/bind 0.0.0.0/' /etc/valkey/valkey.conf &>>$LOG_FILE
sed -i 's/^protected-mode .*/protected-mode no/' /etc/valkey/valkey.conf &>>$LOG_FILE
echo $?

echo -e "\\e[36mStarting Valkey service\\e[0m"
systemctl daemon-reload &>>$LOG_FILE
systemctl enable valkey &>>$LOG_FILE
systemctl restart valkey &>>$LOG_FILE
echo $?

print_footer 0 $SERVICE_NAME
