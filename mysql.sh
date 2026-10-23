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

echo -e "\\e[36mInstalling MySQL 8.4\\e[0m"
dnf install -y mysql8.4-server &>>$LOG_FILE
echo $?

echo -e "\\e[36mStarting MySQL service\\e[0m"
systemctl daemon-reload &>>$LOG_FILE
systemctl enable mysqld &>>$LOG_FILE
systemctl restart mysqld &>>$LOG_FILE
echo $?

echo -e "\\e[36mSetting MySQL root password\\e[0m"
mysql -u root -e "
CREATE USER 'root'@'%' IDENTIFIED BY '${MYSQL_ROOT_PASSWORD}';
GRANT ALL PRIVILEGES ON *.* TO 'root'@'%' WITH GRANT OPTION;
ALTER USER 'root'@'localhost' IDENTIFIED BY '${MYSQL_ROOT_PASSWORD}';
FLUSH PRIVILEGES;
" &>>$LOG_FILE
echo $?

print_footer 0 $SERVICE_NAME
