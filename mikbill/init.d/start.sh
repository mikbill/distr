#!/bin/bash
/usr/sbin/crond start
/usr/sbin/php-fpm -D

while true
do
rm -rf /var/run/mikbill.pid
cd /var/www/mikbill/admin/app/lib
php mikbill.php kernel -d
sleep 5
done
