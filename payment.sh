#!/bin/bash

# ============================================================
# Payment Microservice Script
# ============================================================

# Source common functions
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/common.sh"

# Variables specific to this service
SERVICE_NAME="payment"
SERVICE_PORT="8005"
APP_DIR="/home/roboshop/payment"
AMQP_HOST="${RABBITMQ_HOST}"
AMQP_USER="${RABBITMQ_USER}"
AMQP_PASS="${RABBITMQ_PASSWORD}"
CART_URL="http://${CART_HOST}:${PORT_CART}"
USER_URL="http://${USER_HOST}:${PORT_USER}"
REPO_URL="https://github.com/raghudevopsb89/roboshop-microservices/raw/main/artifacts"

print_header "Payment Service Setup"

# Step 1: Create roboshop user
print_info "Step 1: Creating roboshop user"
create_user || { print_footer 1 $SERVICE_NAME; exit 1; }

# Step 2: Install Python
print_info "Step 2: Installing Python 3"
if ! command -v python3 &>/dev/null; then
    install_packages python3 python3-pip || { print_footer 1 $SERVICE_NAME; exit 1; }
else
    print_info "Python 3 already installed"
    python3 --version
fi

# Step 3: Download and install application
print_info "Step 3: Downloading payment service"
mkdir -p "$APP_DIR"
cd "$APP_DIR" || { print_footer 1 $SERVICE_NAME; exit 1; }

curl -sL "${REPO_URL}/payment.zip" -o /tmp/payment.zip 2>/dev/null
if [ -f /tmp/payment.zip ]; then
    unzip -o /tmp/payment.zip 2>/dev/null || { print_info "Failed to extract, using existing files"; }
    rm -f /tmp/payment.zip
fi

# Install Python dependencies
print_info "Installing Python dependencies"
pip3 install -r requirements.txt 2>/dev/null || { print_info "pip install completed or failed"; }

# Step 4: Set permissions
print_info "Step 4: Setting permissions"
set_permissions "$APP_DIR" || { print_footer 1 $SERVICE_NAME; exit 1; }

# Step 5: Create run script
print_info "Step 5: Creating run script"
cat > /home/roboshop/run_payment.sh << EOF
#!/bin/bash
cd ${APP_DIR} || exit 1
export AMQP_HOST="${AMQP_HOST}"
export AMQP_USER="${AMQP_USER}"
export AMQP_PASS="${AMQP_PASS}"
export CART_URL="${CART_URL}"
export USER_URL="${USER_URL}"
export PORT="${SERVICE_PORT}"
exec /usr/local/bin/uvicorn main:app --host 0.0.0.0 --port ${SERVICE_PORT}
EOF
chmod +x /home/roboshop/run_payment.sh

# Step 6: Configure and start service
print_info "Step 6: Configuring and starting service"
configure_systemd_service_python "${SERVICE_NAME}" "main:app" "${SERVICE_PORT}" || { print_footer 1 $SERVICE_NAME; exit 1; }

start_service "${SERVICE_NAME}" || { print_footer 1 $SERVICE_NAME; exit 1; }

print_footer 0 $SERVICE_NAME
