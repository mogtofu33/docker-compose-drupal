#!/usr/bin/env bash

# Default local variables.
source .env

docker exec \
  -t \
  --user "${PROJECT_CONTAINER_USER}" \
  --interactive "${PROJECT_CONTAINER_NAME}" \
  "${DRUSH_BIN}" "${PROJECT_CONTAINER_ROOT}" "$@"
