#!/bin/bash
docker exec mikbill /var/www/mikbill/admin/sys/update/mikbill_update.sh

docker start mikbill
docker restart nginx
