nodejs_setup() {
  curl -fsSL https://rpm.nodesource.com/setup_20.x | bash -
  dnf install -y nodejs

  rm -rf /app
  useradd -r -s /bin/false appuser
  mkdir -p /app

  curl -L -o /tmp/${app_name}.zip https://raw.githubusercontent.com/raghudevopsb89/roboshop-microservices/main/artifacts/${app_name}.zip
  cd /app
  unzip /tmp/${app_name}.zip
  npm install --production
  chown -R appuser:appuser /app
  chmod o-rwx /app -R

  systemctl daemon-reload
  systemctl enable ${app_name}
  systemctl start ${app_name}
}

