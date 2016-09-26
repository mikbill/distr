#!/bin/bash
/usr/sbin/crond start
/usr/sbin/php-fpm start

while true
do
rm -rf /var/run/mikbill.pid
php /var/www/mikbill/admin/app/lib/mikbill.php kernel -d
sleep 5
done
