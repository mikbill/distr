#!/bin/bash
mysql -uroot -pROOTPASS < /var/lib/mysql/mikbill_5.5.sql
mysql -uroot -pROOTPASS mikbill < /var/lib/mysql/mikbill_2_0_6_utf8.sql
