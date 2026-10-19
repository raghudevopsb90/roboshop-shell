dnf install -y mysql8.4-server
systemctl enable mysqld
systemctl start mysqld

mysql -u root -e "
  CREATE USER 'root'@'%' IDENTIFIED BY 'RoboShop@1';
  GRANT ALL PRIVILEGES ON *.* TO 'root'@'%' WITH GRANT OPTION;
  ALTER USER 'root'@'localhost' IDENTIFIED BY 'RoboShop@1';
  FLUSH PRIVILEGES;
"

