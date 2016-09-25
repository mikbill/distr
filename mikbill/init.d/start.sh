#!/bin/bash
while true
do
# Mikbill
rm -rf /var/run/mikbill.pid
php /var/www/mikbill/admin/app/lib/mikbill.php kernel -d
# Cron
/usr/sbin/crond
# Php-fpm
service php_fpm start

sleep 5
done
