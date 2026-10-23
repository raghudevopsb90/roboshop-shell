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
REPO_URL="https://github.com/raghudevopsb89/roboshop-microservices/raw/main/artifacts"

print_header "Frontend Service Setup"

# Step 1: Install Nginx
print_info "Step 1: Installing Nginx"
if ! is_package_installed nginx; then
    install_packages nginx || { print_footer 1 $SERVICE_NAME; exit 1; }
else
    print_info "Nginx already installed"
fi

# Start and enable Nginx
systemctl daemon-reload 2>/dev/null
systemctl enable nginx 2>/dev/null
systemctl restart nginx 2>/dev/null
if [ $? -ne 0 ]; then
    print_footer 1 $SERVICE_NAME
    exit 1
fi
print_info "Nginx started and enabled"

# Step 2: Install Node.js
print_info "Step 2: Installing Node.js 20"
install_nodejs || { print_footer 1 $SERVICE_NAME; exit 1; }

# Step 3: Download and build frontend application
print_info "Step 3: Downloading and building frontend application"
mkdir -p /tmp/frontend
cd /tmp/frontend || { print_footer 1 $SERVICE_NAME; exit 1; }

curl -sL "${REPO_URL}/frontend.zip" -o /tmp/frontend.zip || { print_info "Using existing frontend files"; }
if [ -f /tmp/frontend.zip ]; then
    unzip -o /tmp/frontend.zip 2>/dev/null || { print_info "Failed to extract, using existing files"; }
    if [ -d /tmp/frontend ] && [ -f /tmp/frontend/package.json ]; then
        print_info "Installing npm dependencies"
        npm install 2>/dev/null || { print_info "npm install failed, continuing..."; }
        
        print_info "Building frontend application"
        npm run build 2>/dev/null || { print_info "npm run build failed, using existing build"; }
        
        if [ -d /tmp/frontend/out ] && [ "$(ls -A /tmp/frontend/out)" ]; then
            print_info "Deploying built frontend to Nginx"
            rm -rf "$APP_DIR"/*
            cp -r /tmp/frontend/out/* "$APP_DIR/"
        else
            print_info "No built frontend found, skipping deployment"
        fi
    fi
fi

# Step 4: Configure Nginx
print_info "Step 4: Configuring Nginx"
cat > /etc/nginx/conf.d/robotshop.conf << EOF
server {
    listen ${NGINX_PORT};
    server_name robotshop.${ROBOTSHOP_DOMAIN};
    
    location / {
        root ${APP_DIR};
        index index.html index.htm;
        try_files \$uri \$uri/ /index.html;
    }
    
    location /api/catalogue/ {
        proxy_pass http://${CATALOGUE_HOST}:${PORT_CATALOGUE};
        proxy_set_header Host \$host;
        proxy_set_header X-Real-IP \$remote_addr;
        proxy_set_header X-Forwarded-For \$proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto \$scheme;
    }
    
    location /api/user/ {
        proxy_pass http://${USER_HOST}:${PORT_USER};
        proxy_set_header Host \$host;
        proxy_set_header X-Real-IP \$remote_addr;
        proxy_set_header X-Forwarded-For \$proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto \$scheme;
    }
    
    location /api/cart/ {
        proxy_pass http://${CART_HOST}:${PORT_CART};
        proxy_set_header Host \$host;
        proxy_set_header X-Real-IP \$remote_addr;
        proxy_set_header X-Forwarded-For \$proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto \$scheme;
    }
    
    location /api/shipping/ {
        proxy_pass http://${SHIPPING_HOST}:${PORT_SHIPPING};
        proxy_set_header Host \$host;
        proxy_set_header X-Real-IP \$remote_addr;
        proxy_set_header X-Forwarded-For \$proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto \$scheme;
    }
    
    location /api/payment/ {
        proxy_pass http://${PAYMENT_HOST}:${PORT_PAYMENT};
        proxy_set_header Host \$host;
        proxy_set_header X-Real-IP \$remote_addr;
        proxy_set_header X-Forwarded-For \$proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto \$scheme;
    }
    
    location /api/ratings {
        proxy_pass http://${RATINGS_HOST}:${PORT_RATINGS};
        proxy_set_header Host \$host;
        proxy_set_header X-Real-IP \$remote_addr;
        proxy_set_header X-Forwarded-For \$proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto \$scheme;
    }
    
    location /api/orders/ {
        proxy_pass http://${ORDERS_HOST}:${PORT_ORDERS};
        proxy_set_header Host \$host;
        proxy_set_header X-Real-IP \$remote_addr;
        proxy_set_header X-Forwarded-For \$proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto \$scheme;
    }
    
    location /api/notification {
        proxy_pass http://${NOTIFICATION_HOST}:${PORT_NOTIFICATION};
        proxy_set_header Host \$host;
        proxy_set_header X-Real-IP \$remote_addr;
        proxy_set_header X-Forwarded-For \$proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto \$scheme;
    }
}
EOF

# Test and restart Nginx
nginx -t 2>/dev/null
if [ $? -eq 0 ]; then
    systemctl restart nginx 2>/dev/null
    print_info "Nginx restarted successfully"
else
    print_info "Nginx config test failed, Nginx not restarted"
fi

# Step 5: Verify
print_info "Step 5: Verifying frontend setup"
 systemctl is-active --quiet nginx 2>/dev/null
if [ $? -eq 0 ]; then
    print_info "Nginx is running"
else
    print_info "Nginx is not running"
fi

print_footer 0 $SERVICE_NAME
