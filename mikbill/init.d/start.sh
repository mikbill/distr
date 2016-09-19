#!/bin/bash
service crond start
service php_fpm start
/usr/local/sbin/mikbill_run.sh
