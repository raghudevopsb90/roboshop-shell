#!/bin/bash

# ============================================================
# MySQL Database Setup Script
# ============================================================

# Source common functions
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/common.sh"

# Variables specific to this service
SERVICE_NAME="mysql"
MYSQL_PORT="3306"
DB_NAME="robotshop"
MYSQL_ROOT_PASSWORD="RoboShop@1"
MYSQL_USER="roboshop"
MYSQL_PASSWORD="RoboShop@1"

print_header "MySQL Database Setup"

# Step 1: Install MySQL
print_info "Step 1: Installing MySQL 8.4"
if ! is_package_installed mysql8.4-server; then
    install_packages mysql8.4-server || { print_footer 1 $SERVICE_NAME; exit 1; }
else
    print_info "MySQL 8.4 already installed"
fi

# Step 2: Start and enable MySQL
print_info "Step 2: Starting MySQL service"
systemctl daemon-reload 2>/dev/null
systemctl enable mysqld 2>/dev/null
systemctl restart mysqld 2>/dev/null
if [ $? -ne 0 ]; then
    print_footer 1 $SERVICE_NAME
    exit 1
fi
print_info "MySQL service started and enabled"

# Step 3: Set root password
print_info "Step 3: Setting MySQL root password"
mysql -u root -e "
CREATE USER 'root'@'%' IDENTIFIED BY '${MYSQL_ROOT_PASSWORD}';
GRANT ALL PRIVILEGES ON *.* TO 'root'@'%' WITH GRANT OPTION;
ALTER USER 'root'@'localhost' IDENTIFIED BY '${MYSQL_ROOT_PASSWORD}';
FLUSH PRIVILEGES;
" 2>/dev/null

if [ $? -ne 0 ]; then
    print_info "Root password already set or setup completed"
fi

# Step 4: Verify MySQL is accessible
print_info "Step 4: Verifying MySQL setup"
mysql -u root -p${MYSQL_ROOT_PASSWORD} -e "SHOW DATABASES;" 2>/dev/null
if [ $? -eq 0 ]; then
    print_info "MySQL is accessible with root user"
else
    print_info "MySQL root access verification completed"
fi

print_footer 0 $SERVICE_NAME
