log_file=/tmp/roboshop.log
## TO have a clean log file, We will remove it.
rm -f $log_file


echo -e \\e[36m Installing Nginx \\e[0m
dnf install -y nginx &>>$log_file
echo $?

echo -e \\e[36m Copy nginx configuration \\e[0m
cp nginx.conf /etc/nginx/nginx.conf &>>$log_file
echo $?

echo -e \\e[36m Install Nodejs \\e[0m
curl -fsSL https://rpm.nodesource.com/setup_20.x | bash - &>>$log_file
dnf install -y nodejs &>>$log_file
echo $?

echo -e \\e[36m Downloading frontend code \\e[0m
curl -L -o /tmp/frontend.zip https://raw.githubusercontent.com/raghudevopsb89/roboshop-microservices/main/artifacts/frontend.zip &>>$log_file
echo $?

rm -rf /tmp/frontend
mkdir -p /tmp/frontend && cd /tmp/frontend

echo -e \\e[36m Extract frontend code \\e[0m
unzip /tmp/frontend.zip &>>$log_file
echo $?

echo -e \\e[36m Compiling Frontend code \\e[0m
npm install &>>$log_file
npm run build &>>$log_file
echo $?

echo -e \\e[36m Copy compile code to nginx \\e[0m
rm -rf /usr/share/nginx/html/* &>>$log_file
cp -r out/* /usr/share/nginx/html/  &>>$log_file
echo $?

echo -e \\e[36m Start Nginx Service \\e[0m
systemctl enable nginx &>>$log_file
systemctl restart nginx &>>$log_file
echo $?

