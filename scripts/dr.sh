#!/usr/bin/env bash

# Default local variables.
_CONTAINER='dcd-php'
_USER='apache'
_DRUPAL_ROOT='--root=/var/www/localhost/drupal/web'
_BIN='/var/www/localhost/drupal/vendor/bin/drush'

docker exec \
  -it \
  --user "${_USER}" \
  --interactive "${_CONTAINER}" \
  "${_BIN}" "${_DRUPAL_ROOT}" "$@"
