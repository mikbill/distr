#!/bin/bash
/usr/sbin/crond start
/usr/sbin/php-fpm -D

cd /var/www/mikbill/admin/app/lib
while true
do
rm -rf /var/run/mikbill.pid
php mikbill.php kernel -d
sleep 5
done
