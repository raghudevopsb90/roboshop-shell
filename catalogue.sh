dnf install -y golang git mysql8.4

cp catalogue.service /etc/systemd/system/catalogue.service

curl -L -o /tmp/catalogue.zip https://raw.githubusercontent.com/raghudevopsb89/roboshop-microservices/main/artifacts/catalogue.zip
mkdir -p /app
cd /app
unzip /tmp/catalogue.zip
mysql -h localhost -u root -pRoboShop@1 < db/schema.sql
mysql -h localhost -u root -pRoboShop@1 < db/app-user.sql
mysql -h localhost -u root -pRoboShop@1 catalogue < db/master-data.sql

useradd -r -s /bin/false appuser
cd /app
go mod tidy
CGO_ENABLED=0 go build -o /app/catalogue .
chown -R appuser:appuser /app
chmod o-rwx /app -R

systemctl daemon-reload
systemctl enable catalogue
systemctl restart catalogue



