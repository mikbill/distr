#!/bin/bash
mysql_root_passwd="passwd"
mysql_mikbill_passwd="passwd"

dir_install="/tmp/install"
dir_config="/etc/mikbill"
dir_base="var/lib/mysql"
dir_log_nginx="/var/log/nginx"
dir_mikbill="/var/www/mikbill"

mkdir $dir_install
wget https://raw.githubusercontent.com/mikbill/distr/master/install/install.lib -O $dir_install/install.lib
source $dir_install/install.lib

RM_MIKBILL
#DOCKER_CLEAR

MKDIR
WGET
NGINX
MYSQL
#MIKBILL_PHP-FPM
#RAD_DHCP
