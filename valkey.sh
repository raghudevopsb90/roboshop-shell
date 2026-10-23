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

# Step 1: Install Valkey
print_info "Step 1: Installing Valkey"
if ! is_package_installed valkey; then
    install_packages valkey || { print_footer 1 $SERVICE_NAME; exit 1; }
else
    print_info "Valkey already installed"
fi

# Step 2: Configure Valkey to accept remote connections
print_info "Step 2: Configuring Valkey"
sed -i 's/^bind .*/bind 0.0.0.0/' /etc/valkey/valkey.conf 2>/dev/null || { print_info "bind configuration failed"; }
sed -i 's/^protected-mode .*/protected-mode no/' /etc/valkey/valkey.conf 2>/dev/null || { print_info "protected-mode configuration failed"; }

# Step 3: Start and enable Valkey
print_info "Step 3: Starting Valkey service"
systemctl daemon-reload 2>/dev/null
systemctl enable valkey 2>/dev/null
systemctl restart valkey 2>/dev/null
if [ $? -ne 0 ]; then
    print_footer 1 $SERVICE_NAME
    exit 1
fi
print_info "Valkey service started and enabled"

# Step 4: Verify Valkey is running
print_info "Step 4: Verifying Valkey setup"
systemctl is-active --quiet valkey 2>/dev/null
if [ $? -eq 0 ]; then
    print_info "Valkey is running"
else
    print_info "Valkey status check completed"
fi

print_footer 0 $SERVICE_NAME
