#!/bin/bash

# ============================================================
# Frontend Microservice Script
# ============================================================

# Source common functions
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/common.sh"

# Variables specific to this service
SERVICE_NAME="frontend"
NGINX_PORT="80"
FRONTEND_PORT="3000"
APP_DIR="/usr/share/nginx/html"
NGINX_CONF_FILE="${SCRIPT_DIR}/nginx.conf"
REPO_URL="https://raw.githubusercontent.com/raghudevopsb89/roboshop-microservices/main/artifacts"

print_header "Frontend Service Setup"

echo -e "\\e[36mInstalling Nginx\\e[0m"
dnf install -y nginx &>>$LOG_FILE
echo $?

echo -e "\\e[36mCopying nginx configuration\\e[0m"
cp "${NGINX_CONF_FILE}" /etc/nginx/nginx.conf &>>$LOG_FILE
echo $?

echo -e "\\e[36mInstalling Node.js\\e[0m"
curl -sL https://rpm.nodesource.com/setup_20.x | bash - &>>$LOG_FILE
dnf install -y nodejs &>>$LOG_FILE
echo $?

echo -e "\\e[36mDownloading frontend code\\e[0m"
curl -L -o /tmp/frontend.zip "${REPO_URL}/frontend.zip" &>>$LOG_FILE
echo $?

rm -rf /tmp/frontend
mkdir -p /tmp/frontend && cd /tmp/frontend

echo -e "\\e[36mExtracting frontend code\\e[0m"
unzip /tmp/frontend.zip &>>$LOG_FILE
echo $?

echo -e "\\e[36mCompiling Frontend code\\e[0m"
npm install &>>$LOG_FILE
npm run build &>>$LOG_FILE
echo $?

echo -e "\\e[36mCopying compiled code to nginx\\e[0m"
rm -rf /usr/share/nginx/html/* &>>$LOG_FILE
cp -r out/* /usr/share/nginx/html/ &>>$LOG_FILE
echo $?

echo -e "\\e[36mStarting Nginx Service\\e[0m"
systemctl enable nginx &>>$LOG_FILE
systemctl restart nginx &>>$LOG_FILE
echo $?

print_footer 0 $SERVICE_NAME
