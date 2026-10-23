#!/bin/bash

# ============================================================
# RoboShop Common Variables and Functions
# ============================================================

# Log file configuration
LOG_FILE="/tmp/roboshop.log"

# Remove old log file for clean log
rm -f $LOG_FILE

# Global Configuration
ROBOTSHOP_DOMAIN="rdevopsb90.online"
APP_USER="roboshop"
APP_GROUP="roboshop"

# ============================================================
# Service Endpoints (DNS-based)
# ============================================================

MYSQL_HOST="mysql.${ROBOTSHOP_DOMAIN}"
MONGODB_HOST="mongodb.${ROBOTSHOP_DOMAIN}"
VALKEY_HOST="valkey.${ROBOTSHOP_DOMAIN}"
RABBITMQ_HOST="rabbitmq.${ROBOTSHOP_DOMAIN}"
CATALOGUE_HOST="catalogue.${ROBOTSHOP_DOMAIN}"
USER_HOST="user.${ROBOTSHOP_DOMAIN}"
CART_HOST="cart.${ROBOTSHOP_DOMAIN}"
SHIPPING_HOST="shipping.${ROBOTSHOP_DOMAIN}"
RATINGS_HOST="ratings.${ROBOTSHOP_DOMAIN}"
ORDERS_HOST="orders.${ROBOTSHOP_DOMAIN}"
NOTIFICATION_HOST="notification.${ROBOTSHOP_DOMAIN}"

# ============================================================
# Passwords
# ============================================================

MYSQL_ROOT_PASSWORD="RoboShop@1"
MYSQL_APP_PASSWORD="RoboShop@1"
MONGODB_PASSWORD="RoboShop@1"
VALKEY_PASSWORD="RoboShop@1"
RABBITMQ_PASSWORD="RoboShop@1"
RABBITMQ_USER="roboshop"
RABBITMQ_USER_PASSWORD="RoboShop@1"

# ============================================================
# Service Ports
# ============================================================

PORT_USER="8001"
PORT_CATALOGUE="8002"
PORT_CART="8003"
PORT_SHIPPING="8004"
PORT_PAYMENT="8005"
PORT_RATINGS="8006"
PORT_ORDERS="8007"
PORT_NOTIFICATION="8008"
PORT_MYSQL="3306"
PORT_MONGODB="27017"
PORT_VALKEY="6379"
PORT_RABBITMQ="5672"
PORT_RABBITMQ_MANAGEMENT="15672"
PORT_NGINX="80"
PORT_FRONTEND="3000"

# ============================================================
# Utility Functions
# ============================================================

# Print section header
print_header() {
    local service_name=$1
    echo "=================================================="
    echo "START: ${service_name} Setup"
    echo "=================================================="
}

# Print section footer with exit status
print_footer() {
    local exit_code=$1
    local service_name=$2
    if [ $exit_code -eq 0 ]; then
        echo "=================================================="
        echo "SUCCESS: ${service_name}"
        echo "=================================================="
    else
        echo "=================================================="
        echo "FAILURE: ${service_name}"
        echo "=================================================="
    fi
}

# Print info message with colored output
print_info() {
    echo -e "\\e[36m$1\\e[0m"
}

# Print error message and exit
print_error() {
    echo -e "\\e[31m[ERROR]\\e[0m $1"
    exit 1
}

# Install required packages
install_packages() {
    local packages=("$@")
    if [ ${#packages[@]} -gt 0 ]; then
        print_info "Installing packages: ${packages[*]}"
        dnf install -y "${packages[@]}" &>>$LOG_FILE
        return $?
    fi
}

# Create user if not exists
create_user() {
    print_info "Checking if user ${APP_USER} exists"
    if ! id "$APP_USER" &>/dev/null; then
        print_info "Creating user: ${APP_USER}"
        useradd -M -s /sbin/nologin "$APP_USER" &>>$LOG_FILE
        return $?
    fi
    print_info "User ${APP_USER} already exists"
    return 0
}

# Create appuser if not exists (for running services)
create_appuser() {
    print_info "Checking if appuser exists"
    if ! id "appuser" &>/dev/null; then
        print_info "Creating appuser"
        useradd -r -s /bin/false appuser &>>$LOG_FILE
        return $?
    fi
    print_info "appuser already exists"
    return 0
}

# Set directory permissions
set_permissions() {
    local dir=$1
    local owner=${2:-$APP_USER}
    print_info "Setting permissions on ${dir} for ${owner}"
    chown -R "$owner":"$owner" "$dir" &>>$LOG_FILE
    chmod -R 755 "$dir" &>>$LOG_FILE
    return $?
}

# Check if service is running
is_service_running() {
    local service_name=$1
    systemctl is-active --quiet "$service_name" 2>/dev/null
    return $?
}

# Start service
start_service() {
    local service_name=$1
    print_info "Starting service: ${service_name}"
    systemctl daemon-reload &>>$LOG_FILE
    systemctl enable "$service_name" &>>$LOG_FILE
    systemctl restart "$service_name" &>>$LOG_FILE
    return $?
}

# Reload systemd and restart service
reload_and_restart_service() {
    local service_name=$1
    print_info "Reloading systemd and restarting ${service_name}"
    systemctl daemon-reload &>>$LOG_FILE
    systemctl restart "$service_name" &>>$LOG_FILE
    return $?
}

# Check if package is installed
is_package_installed() {
    local package=$1
    rpm -q "$package" &>/dev/null
    return $?
}

# Install Node.js 20
install_nodejs() {
    print_info "Checking Node.js installation"
    if ! command -v node &>/dev/null; then
        print_info "Installing Node.js 20"
        curl -sL https://rpm.nodesource.com/setup_20.x | bash - &>>$LOG_FILE
        install_packages nodejs || return $?
    else
        print_info "Node.js already installed"
        node --version
    fi
}

# Configure systemd service for shell script execution
configure_systemd_service() {
    local service_name=$1
    local exec_start=$2
    local port=$3
    local service_file="/etc/systemd/system/${service_name}.service"
    
    print_info "Configuring systemd service for ${service_name}"
    
    cat > "$service_file" << EOF
[Unit]
Description=RoboShop ${service_name} Service
After=network.target

[Service]
Type=simple
User=${APP_USER}
Group=${APP_GROUP}
ExecStart=${exec_start}
Restart=on-failure
RestartSec=5
StandardOutput=journal
StandardError=journal

[Install]
WantedBy=multi-user.target
EOF
    return $?
}

# Configure systemd service for Java jar execution
configure_systemd_service_java() {
    local service_name=$1
    local jar_path=$2
    local port=$3
    local service_file="/etc/systemd/system/${service_name}.service"
    
    print_info "Configuring systemd service for ${service_name} (Java)"
    
    cat > "$service_file" << EOF
[Unit]
Description=RoboShop ${service_name} Service
After=network.target

[Service]
Type=simple
User=${APP_USER}
Group=${APP_GROUP}
ExecStart=/usr/bin/java -jar ${jar_path}
Restart=on-failure
RestartSec=5
StandardOutput=journal
StandardError=journal

[Install]
WantedBy=multi-user.target
EOF
    return $?
}

# Configure systemd service for Python uvicorn execution
configure_systemd_service_python() {
    local service_name=$1
    local app_path=$2
    local port=$3
    local service_file="/etc/systemd/system/${service_name}.service"
    
    print_info "Configuring systemd service for ${service_name} (Python)"
    
    cat > "$service_file" << EOF
[Unit]
Description=RoboShop ${service_name} Service
After=network.target

[Service]
Type=simple
User=${APP_USER}
Group=${APP_GROUP}
ExecStart=/usr/local/bin/uvicorn ${app_path} --host 0.0.0.0 --port ${port}
Restart=on-failure
RestartSec=5
StandardOutput=journal
StandardError=journal

[Install]
WantedBy=multi-user.target
EOF
    return $?
}

# Configure systemd service for Python gunicorn execution
configure_systemd_service_gunicorn() {
    local service_name=$1
    local app_path=$2
    local port=$3
    local service_file="/etc/systemd/system/${service_name}.service"
    
    print_info "Configuring systemd service for ${service_name} (Gunicorn)"
    
    cat > "$service_file" << EOF
[Unit]
Description=RoboShop ${service_name} Service
After=network.target

[Service]
Type=simple
User=${APP_USER}
Group=${APP_GROUP}
ExecStart=/usr/local/bin/gunicorn -b 0.0.0.0:${port} ${app_path}
Restart=on-failure
RestartSec=5
StandardOutput=journal
StandardError=journal

[Install]
WantedBy=multi-user.target
EOF
    return $?
}

# Download and extract artifact
download_and_extract() {
    local url=$1
    local dest_dir=$2
    local artifact_name=${3:-artifact}
    
    print_info "Downloading ${artifact_name}"
    local zip_file="/tmp/${artifact_name}.zip"
    
    curl -sL "$url" -o "$zip_file" &>>$LOG_FILE
    if [ $? -ne 0 ]; then
        print_error "Failed to download ${artifact_name}"
    fi
    
    print_info "Extracting ${artifact_name} to ${dest_dir}"
    mkdir -p "$dest_dir"
    unzip -o "$zip_file" -d "$dest_dir" &>>$LOG_FILE
    if [ $? -ne 0 ]; then
        print_error "Failed to extract ${artifact_name}"
    fi
    
    rm -f "$zip_file"
    return $?
}

# Check for failed systemd service
check_service_status() {
    local service_name=$1
    systemctl is-active --quiet "$service_name" 2>/dev/null
    return $?
}
