#!/bin/bash
docker exec MIKBILL rm -f /var/www/mikbill/admin/sys/update/mikbill_current
docker exec MIKBILL /var/www/mikbill/admin/sys/update/mikbill_update.sh

docker restart RADIUS MIKBILL

docker ps
