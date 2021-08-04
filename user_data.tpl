#!/bin/bash
echo hello
yum update -y
yum install -y httpd git php-gd
amazon-linux-extras install -y lamp-mariadb10.2-php7.2 php7.2

wget https://wordpress.org/latest.tar.gz
tar -xzf latest.tar.gz

git clone https://github.com/gerryhzgtest2021/DevOps_terraform_wordpress
cp -R DevOps_terraform_wordpress/share/wp-config.php wordpress/wp-config.php
sed -i "s/'mysqldb'/'${db_name}'/" wordpress/wp-config.php
sed -i "s/'tempunsecurepassword'/'${db_password}'/" wordpress/wp-config.php
sed -i "s/'conenction string of your RDS'/'${db_address}'/" wordpress/wp-config.php
cp -r wordpress/* /var/www/html/
rm -rf /etc/httpd/conf/httpd.conf
cp -R DevOps_terraform_wordpress/share/httpd.conf /etc/httpd/conf/httpd.conf

chown -R apache /var/www
chmod -R 700 /var/www

systemctl start httpd && systemctl enable httpd