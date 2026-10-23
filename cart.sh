#!/bin/bash

# ============================================================
# Cart Microservice Script
# ============================================================

# Source common functions
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/common.sh"

# Variables specific to this service
SERVICE_NAME="cart"
SERVICE_PORT="8003"
APP_DIR="/home/roboshop/cart"
REDIS_HOST="${VALKEY_HOST}"
CATALOGUE_URL="http://${CATALOGUE_HOST}:${PORT_CATALOGUE}"
REPO_URL="https://github.com/raghudevopsb89/roboshop-microservices/raw/main/artifacts"

print_header "Cart Service Setup"

# Step 1: Create roboshop user
print_info "Step 1: Creating roboshop user"
create_user || { print_footer 1 $SERVICE_NAME; exit 1; }

# Step 2: Install Node.js
print_info "Step 2: Installing Node.js 20"
install_nodejs || { print_footer 1 $SERVICE_NAME; exit 1; }

# Step 3: Download and install application
print_info "Step 3: Downloading cart service"
mkdir -p "$APP_DIR"
cd "$APP_DIR" || { print_footer 1 $SERVICE_NAME; exit 1; }

curl -sL "${REPO_URL}/cart.zip" -o /tmp/cart.zip 2>/dev/null
if [ -f /tmp/cart.zip ]; then
    unzip -o /tmp/cart.zip 2>/dev/null || { print_info "Failed to extract, using existing files"; }
    rm -f /tmp/cart.zip
fi

# Install npm dependencies
print_info "Installing npm dependencies"
npm install --production 2>/dev/null || { print_info "npm install completed or failed"; }

# Step 4: Set permissions
print_info "Step 4: Setting permissions"
set_permissions "$APP_DIR" || { print_footer 1 $SERVICE_NAME; exit 1; }

# Step 5: Create run script
print_info "Step 5: Creating run script"
cat > /home/roboshop/run_cart.sh << EOF
#!/bin/bash
cd ${APP_DIR} || exit 1
export REDIS_HOST="${REDIS_HOST}"
export CATALOGUE_URL="${CATALOGUE_URL}"
export PORT="${SERVICE_PORT}"
exec /usr/bin/node server.js
EOF
chmod +x /home/roboshop/run_cart.sh

# Step 6: Configure and start service
print_info "Step 6: Configuring and starting service"
configure_systemd_service "${SERVICE_NAME}" "/bin/bash /home/roboshop/run_cart.sh" "${SERVICE_PORT}" || { print_footer 1 $SERVICE_NAME; exit 1; }

start_service "${SERVICE_NAME}" || { print_footer 1 $SERVICE_NAME; exit 1; }

print_footer 0 $SERVICE_NAME
