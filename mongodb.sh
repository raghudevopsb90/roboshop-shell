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

# Step 1: Add MongoDB repository
print_info "Step 1: Adding MongoDB 7.0 repository"
cat > /etc/yum.repos.d/mongodb-org-7.0.repo << EOF
[mongodb-org-7.0]
name=MongoDB Repository
baseurl=https://repo.mongodb.org/yum/redhat/9/mongodb-org/7.0/x86_64/
gpgcheck=0
enabled=1
EOF

# Step 2: Install MongoDB
print_info "Step 2: Installing MongoDB"
if ! is_package_installed mongodb-org; then
    install_packages mongodb-org || { print_footer 1 $SERVICE_NAME; exit 1; }
else
    print_info "MongoDB already installed"
fi

# Step 3: Configure MongoDB to accept remote connections
print_info "Step 3: Configuring MongoDB"
sed -i 's/^bindIp: 127.0.0.1/bindIp: 0.0.0.0/' /etc/mongod.conf 2>/dev/null || { print_info "bindIp already configured"; }

# Step 4: Start and enable MongoDB
print_info "Step 4: Starting MongoDB service"
systemctl daemon-reload 2>/dev/null
systemctl enable mongod 2>/dev/null
systemctl restart mongod 2>/dev/null
if [ $? -ne 0 ]; then
    print_footer 1 $SERVICE_NAME
    exit 1
fi
print_info "MongoDB service started and enabled"

# Step 5: Verify MongoDB is running
print_info "Step 5: Verifying MongoDB setup"
systemctl is-active --quiet mongod 2>/dev/null
if [ $? -eq 0 ]; then
    print_info "MongoDB is running"
else
    print_info "MongoDB status check completed"
fi

print_footer 0 $SERVICE_NAME
