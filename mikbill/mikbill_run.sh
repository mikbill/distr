#!/bin/sh

UNAME=`which uname`
SYSTEM=`$UNAME`
MIKBILL_PATH_LINUX="/var/www/mikbill"
MIKBILL_PATH_BSD="/usr/local/www/mikbill"
MIKBILL_PID="/var/run/mikbill.pid"
APP_PHP=`which php`

while true
do

case $SYSTEM in
Linux)
    cd $MIKBILL_PATH_LINUX/admin/app/lib
    ;;
FreeBSD)
    cd $MIKBILL_PATH_BSD/admin/app/lib
    ;;
esac

rm -rf $MIKBILL_PID >/dev/null

$APP_PHP ./mikbill.php kernel -d

sleep 3

done
