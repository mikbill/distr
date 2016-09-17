#!/bin/bash
mysql_root_passwd="passwd"
mysql_mikbill_passwd="passwd"

dir_root="/opt/mikbill"
dir_install="$dir_root/install"
dir_conf="$dir_root/conf"
dir_base="$dir_root/base"
dir_log_nginx="$dir_root/log/nginx"
dir_mikbill="$dir_root/www"

mkdir $dir_install
wget https://raw.githubusercontent.com/mikbill/distr/master/install/install.lib -O $dir_install/install.lib
source $dir_install/install.lib

# Очистка каталогов
RM_MIKBILL
# Удаление всех образов и контейнеров в системе
#DOCKER_CLEAR
# Создание каталогов
MKDIR
# Загрузка всех файлов
WGET
# Установка контейнера Nginx
NGINX
# Установка контейнера MySQL
MYSQL
# Установка контейнера Mikbill
#MIKBILL_PHP-FPM
# Установка контейнера Radius_DHCP
#RAD_DHCP
