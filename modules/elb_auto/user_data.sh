#!/bin/bash
mkdir git_clone
cd git_clone
git clone https://github.com/gabrielecirulli/2048
sudo yum update -y
sudo yum install -y httpd
cp . /var/www/html/
sudo systemctl start httpd
sudo systemctl enable httpd
