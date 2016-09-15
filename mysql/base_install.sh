#!/bin/bash
mysql -uroot -pROOTPASS < /var/lib/mysql/mikbill_5.5.sql
mysql -uroot -pROOTPASS mikbill < /var/lib/mysql/mikbill_2_0_6_utf8.sql

rm -f /etc/mikbill/my.cnf
mv var/lib/mysql/my-mikbill.cnf /etc/mysql/conf.d/my.cnf

rm -f var/lib/mysql/ib_logfile0
rm -f var/lib/mysql/ib_logfile1
rm -f var/lib/mysql/ibdata1
