#!/bin/bash
docker exec mikbill rm -f mikbill_current
docker exec mikbill /var/www/mikbill/admin/sys/update/mikbill_update.sh

./start.sh

docker ps
