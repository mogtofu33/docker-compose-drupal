#!/bin/bash

set -e

__db_dump="/docker-entrypoint-initdb.d/dump.pg_dump"

if [ -f "$__db_dump" ]; then
  printf "[info] Found DB file to import: %s\\n" "$__db_dump"
  pg_restore --no-owner --role "$POSTGRES_USER" -U "$POSTGRES_USER" -d "$POSTGRES_DB" "$__db_dump"
else
  printf "[info] No DB import file.\\nYou can put a file dump.pg_dump in folder ./database-pgsql-init, it will be automatically imported when starting the stack.\\n"
fi
