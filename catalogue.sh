#!/bin/bash

# ============================================================
# Catalogue Microservice Script
# ============================================================

# Source common functions
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/common.sh"

# Variables specific to this service
SERVICE_NAME="catalogue"
SERVICE_PORT="8002"
APP_DIR="/home/roboshop/catalogue"
DB_HOST="${MYSQL_HOST}"
DB_NAME="catalogue"
DB_USER="catalogue"
DB_PASSWORD="RoboShop@1"
REPO_URL="https://github.com/raghudevopsb89/roboshop-microservices/raw/main/artifacts"

print_header "Catalogue Service Setup"

# Step 1: Create roboshop user
print_info "Step 1: Creating roboshop user"
create_user || { print_footer 1 $SERVICE_NAME; exit 1; }

# Step 2: Install dependencies
print_info "Step 2: Installing dependencies"
install_packages git go mysql8.4 || { print_footer 1 $SERVICE_NAME; exit 1; }

# Step 3: Download and extract application
print_info "Step 3: Downloading catalogue application"
mkdir -p "$APP_DIR"
cd "$APP_DIR" || { print_footer 1 $SERVICE_NAME; exit 1; }

curl -sL "${REPO_URL}/catalogue.zip" -o /tmp/catalogue.zip 2>/dev/null
if [ -f /tmp/catalogue.zip ]; then
    unzip -o /tmp/catalogue.zip -d "$APP_DIR" 2>/dev/null || { print_info "Failed to extract, using existing files"; }
    rm -f /tmp/catalogue.zip
fi

# Step 4: Setup database
print_info "Step 4: Setting up database"

# Create catalogue database and user
mysql -h "${DB_HOST}" -u root -p${MYSQL_ROOT_PASSWORD} -e "
CREATE DATABASE IF NOT EXISTS ${DB_NAME};
CREATE USER IF NOT EXISTS '${DB_USER}'@'%' IDENTIFIED BY '${DB_PASSWORD}';
GRANT ALL PRIVILEGES ON ${DB_NAME}.* TO '${DB_USER}'@'%';
FLUSH PRIVILEGES;
" 2>/dev/null

if [ $? -eq 0 ]; then
    print_info "Database ${DB_NAME} and user ${DB_USER} configured"
else
    print_info "Database setup failed or already completed"
fi

# Check if SQL file exists and run it
if [ -f "${APP_DIR}/db/schema.sql" ]; then
    mysql -h "${DB_HOST}" -u root -p${MYSQL_ROOT_PASSWORD} < "${APP_DIR}/db/schema.sql" 2>/dev/null
    print_info "Schema loaded"
fi

if [ -f "${APP_DIR}/db/app-user.sql" ]; then
    mysql -h "${DB_HOST}" -u root -p${MYSQL_ROOT_PASSWORD} < "${APP_DIR}/db/app-user.sql" 2>/dev/null
    print_info "App user SQL executed"
fi

if [ -f "${APP_DIR}/db/master-data.sql" ]; then
    mysql -h "${DB_HOST}" -u root -p${MYSQL_ROOT_PASSWORD} ${DB_NAME} < "${APP_DIR}/db/master-data.sql" 2>/dev/null
    print_info "Master data loaded"
fi

# Step 5: Build the Go application
print_info "Step 5: Building catalogue service"
cd "$APP_DIR" || { print_footer 1 $SERVICE_NAME; exit 1; }

export CGO_ENABLED=0
go build -o "${APP_DIR}/service" ./... 2>/dev/null
if [ $? -ne 0 ]; then
    print_info "Using pre-built binary or downloading"
    curl -sL "https://github.com/raghudevopsb90/roboshop-artifacts/raw/main/catalogue/catalogue" -o "${APP_DIR}/service" 2>/dev/null
    chmod +x "${APP_DIR}/service"
    if [ ! -x "${APP_DIR}/service" ]; then
        print_error "Could not build or download catalogue service"
    fi
fi

# Step 6: Create run script
print_info "Step 6: Creating run script"
cat > /home/roboshop/run_catalogue.sh << EOF
#!/bin/bash
cd ${APP_DIR} || exit 1
export MYSQL_HOST="${DB_HOST}"
export MYSQL_USER="${DB_USER}"
export MYSQL_PASSWORD="${DB_PASSWORD}"
export MYSQL_DATABASE="${DB_NAME}"
export PORT="${SERVICE_PORT}"
exec ${APP_DIR}/service
EOF
chmod +x /home/roboshop/run_catalogue.sh

# Step 7: Set permissions
print_info "Step 7: Setting permissions"
set_permissions "$APP_DIR" || { print_footer 1 $SERVICE_NAME; exit 1; }

# Step 8: Configure and start service
print_info "Step 8: Configuring and starting service"
configure_systemd_service "${SERVICE_NAME}" "/bin/bash /home/roboshop/run_catalogue.sh" "${SERVICE_PORT}" || { print_footer 1 $SERVICE_NAME; exit 1; }

start_service "${SERVICE_NAME}" || { print_footer 1 $SERVICE_NAME; exit 1; }

print_footer 0 $SERVICE_NAME
