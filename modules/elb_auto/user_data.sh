#!/bin/bash
sudo yum update -y
sudo yum install -y httpd git
git clone https://github.com/gabrielecirulli/2048
cp -R 2048/* /var/www/html/
sudo systemctl start httpd
sudo systemctl enable httpd
sudo yum install -y wordpress php libapache2-mod-php mysql-server php-mysql
git clone https://github.com/gerryhzgtest2021/share
cp -R share/wordpress_conf.txt /etc/apache2/sites-available/wordpress.conf
sudo a2ensite wordpress
sudo a2enmod rewrite
sudo service apache2 reload

