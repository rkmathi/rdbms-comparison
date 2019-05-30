#!/bin/bash

set -eux

SCRIPT_DIR=$(cd $(dirname $BASH_SOURCE); pwd)

cd "$SCRIPT_DIR"

docker-compose exec mysql /bin/bash -c "mysql -uuser -ppass comp_db < '/docker-entry-point-initdb.d/0-create-table.sql'"

./generate-insert-sql.rb ./initdb.d/1-insert-data.sql
docker-compose exec mysql /bin/bash -c "mysql -uuser -ppass comp_db < '/docker-entry-point-initdb.d/1-insert-data.sql'"
