#!/usr/bin/env bash

docker exec \
  -it \
  --user apache \
  --interactive dcd-php \
  /var/www/localhost/drupal/vendor/bin/drupal --root=/var/www/localhost/drupal/web "$@"