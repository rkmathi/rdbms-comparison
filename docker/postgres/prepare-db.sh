#!/bin/bash

set -eux

SCRIPT_DIR=$(cd $(dirname $BASH_SOURCE); pwd)

cd "$SCRIPT_DIR"

./generate-insert-sql.rb ./initdb.d/1-insert-data.sql
