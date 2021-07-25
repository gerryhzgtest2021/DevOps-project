#!/bin/bash
sudo yum update -y
sudo yum install -y httpd git
#git clone https://github.com/gabrielecirulli/2048
#cp -R 2048/* /var/www/html/

sudo amazon-linux-extras install -y lamp-mariadb10.2-php7.2 php7.2
sudo yum install -y mariadb-server

#Add your user (in this case, ec2-user) to the apache group.
sudo usermod -a -G apache ec2-user
#Change the group ownership of /var/www and its contents to the apache group.
sudo chown -R ec2-user:apache /var/www
#To add group write permissions and to set the group ID on future subdirectories,
# change the directory permissions of /var/www and its subdirectories.
sudo chmod 2775 /var/www && find /var/www -type d -exec sudo chmod 2775 {} \;
#To add group write permissions, recursively change the file permissions of
# /var/www and its subdirectories:
find /var/www -type f -exec sudo chmod 0664 {} \;

wget https://wordpress.org/latest.tar.gz
tar -xzf latest.tar.gz
sudo systemctl start mariadb
mysql -u root -e "CREATE USER 'wordpress_user'@'localhost' IDENTIFIED BY 'your_strong_password';"
mysql -u root -e "CREATE DATABASE \`wordpress_db\`;"
mysql -u root -e "GRANT ALL PRIVILEGES ON \`wordpress_db\`.* TO 'wordpress_user'@'localhost';"
mysql -u root -e "FLUSH PRIVILEGES;"
git clone https://github.com/gerryhzgtest2021/share
cp -R share/wp-config.php wordpress/wp-config.php
sudo cp -r wordpress/* /var/www/html/
cp -R share/httpd.conf /etc/httpd/conf/httpd.conf
sudo yum install -y php-gd
sudo chown -R apache /var/www
sudo chgrp -R apache /var/www

#Change the directory permissions of /var/www and
#its subdirectories to add group write permissions and to set the group ID on
#future subdirectories.
sudo chmod 2775 /var/www
find /var/www -type d -exec sudo chmod 2775 {} \;
#Recursively change the file permissions of /var/www and its subdirectories to add
#group write permissions.
find /var/www -type f -exec sudo chmod 0664 {} \;

sudo systemctl enable httpd && sudo systemctl enable mariadb
sudo systemctl start mariadb
sudo systemctl start httpd



#sudo yum install -y wordpress php libapache2-mod-php mysql-server php-mysql
#git clone https://github.com/gerryhzgtest2021/share
#cp -R share/wordpress_conf.txt /etc/apache2/sites-available/wordpress.conf
#echo ${wordpress_conf} > /etc/apache2/sites-available/wordpress.conf
#sudo a2ensite wordpress
#sudo a2enmod rewrite
#sudo service apache2 reload
#sudo mysql -u root
#CREATE DATABASE wordpress;
#GRANT SELECT,INSERT,UPDATE,DELETE,CREATE,DROP,ALTER
#ON wordpress.*
#TO wordpress@localhost
#IDENTIFIED BY '<your-password>';
#FLUSH PRIVILEGES;
#quit
#echo ${localhost_php} > /etc/wordpress/config-localhost.php
#sudo service mysql start
