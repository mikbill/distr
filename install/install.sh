#!/bin/bash
mysql_root_passwd="passwd"
mysql_mikbill_passwd="passwd"
# Где будут лежать рабочие конфиги/база
dir_root="/opt/cloud"
# Каталог для загрузки и с которого будет установка
dir_download="/opt/install"

container_mikbill="mikbill"
container_mysql="mysql"
container_nginx="nginx"
container_radius="radius"
# Загрузка библиотеки
mkdir $dir_download 
wget -O $dir_download/install.lib https://raw.githubusercontent.com/mikbill/distr/master/install/install.lib
source $dir_download/install.lib

# install_docker

# Загрузка файлов
download (){
download_mysql
download_nginx
download_mikbill
download_mikbill_www
download_radius
download_control
}
download
# Установка
install (){
install_mysql
install_nginx
install_mikbill
install_radius
install_control
}
#debug
# Установка скрипта платных обновлений
# paid_updates
install

# Удаление установочных файлов
#install_clear

# update_mikbill

docker ps
