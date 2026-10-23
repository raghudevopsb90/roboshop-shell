#!/bin/bash

# ============================================================
# MongoDB Database Setup Script
# ============================================================

# Source common functions
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/common.sh"

# Variables specific to this service
SERVICE_NAME="mongodb"
MONGODB_PORT="27017"
MONGODB_PASSWORD="RoboShop@1"

print_header "MongoDB Database Setup"

echo -e "\\e[36mAdding MongoDB 7.0 repository\\e[0m"
cat > /etc/yum.repos.d/mongodb-org-7.0.repo << EOF
[mongodb-org-7.0]
name=MongoDB Repository
baseurl=https://repo.mongodb.org/yum/redhat/9/mongodb-org/7.0/x86_64/
gpgcheck=0
enabled=1
EOF
echo $?

echo -e "\\e[36mInstalling MongoDB\\e[0m"
dnf install -y mongodb-org &>>$LOG_FILE
echo $?

echo -e "\\e[36mConfiguring MongoDB\\e[0m"
sed -i 's/^bindIp: 127.0.0.1/bindIp: 0.0.0.0/' /etc/mongod.conf &>>$LOG_FILE
echo $?

echo -e "\\e[36mStarting MongoDB service\\e[0m"
systemctl daemon-reload &>>$LOG_FILE
systemctl enable mongod &>>$LOG_FILE
systemctl restart mongod &>>$LOG_FILE
echo $?

print_footer 0 $SERVICE_NAME
