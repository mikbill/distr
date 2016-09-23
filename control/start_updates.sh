#!/bin/bash
docker exec mikbill rm -f /var/www/mikbill/admin/sys/update/mikbill_current
docker exec mikbill /var/www/mikbill/admin/sys/update/mikbill_update.sh

docker mikbill restart

docker ps
