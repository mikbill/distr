#!/bin/bash
mysql_root_passwd="passwd"
mysql_mikbill_passwd="passwd"
HOME_DIR=$(cd $(dirname $0)&& pwd)
source $HOME_DIR/install.lib

RM_MIKBILL
#DOCKER_CLEAR

MKDIR
WGET
NGINX
MYSQL
#MIKBILL_PHP-FPM
#RAD_DHCP
