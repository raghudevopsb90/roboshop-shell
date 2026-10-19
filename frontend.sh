## TO have a clean log file, We will remove it.
rm -f /tmp/frontend.log


echo -e \\e[36m Installing Nginx \\e[0m
dnf install -y nginx &>>/tmp/frontend.log

echo -e \\e[36m Copy nginx configuration \\e[0m
cp nginx.conf /etc/nginx/nginx.conf &>>/tmp/frontend.log

echo -e \\e[36m Install Nodejs \\e[0m
curl -fsSL https://rpm.nodesource.com/setup_20.x | bash - &>>/tmp/frontend.log
dnf install -y nodejs &>>/tmp/frontend.log

echo -e \\e[36m Downloading frontend code \\e[0m
curl -L -o /tmp/frontend.zip https://raw.githubusercontent.com/raghudevopsb89/roboshop-microservices/main/artifacts/frontend.zip &>>/tmp/frontend.log

rm -rf /tmp/frontend
mkdir -p /tmp/frontend && cd /tmp/frontend

echo -e \\e[36m Extract frontend code \\e[0m
unzip /tmp/frontend.zip &>>/tmp/frontend.log

echo -e \\e[36m Compiling Frontend code \\e[0m
npm install &>>/tmp/frontend.log
npm run build &>>/tmp/frontend.log

echo -e \\e[36m Copy compile code to nginx \\e[0m
rm -rf /usr/share/nginx/html/* &>>/tmp/frontend.log
cp -r out/* /usr/share/nginx/html/  &>>/tmp/frontend.log

echo -e \\e[36m Start Nginx Service \\e[0m
systemctl enable nginx &>>/tmp/frontend.log
systemctl restart nginx &>>/tmp/frontend.log


