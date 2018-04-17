#!/usr/bin/env bash

# Default local variables.
_CONTAINER='dcd-php'
_USER='apache'

docker exec \
  -it \
  --user "${_USER}" \
  --interactive "${_CONTAINER}" \
  "$@"
