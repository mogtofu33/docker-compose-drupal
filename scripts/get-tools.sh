#!/bin/bash

# Helper to get third party tools, must be run from parent folder.

SOURCE="${BASH_SOURCE[0]}"
BASENAME=`basename $0`

if [[ $SOURCE != "./scripts/$BASENAME" ]]; then
  echo -e "This script must be run from the root of this project:"
  echo -e "./scripts/$BASENAME"
  exit;
fi

if [[ $1 == 'update' ]]
then
  git -C data/www/TOOLS/PimpMyLog pull origin master
  git -C data/www/TOOLS/PhpMemcachedAdmin pull origin master
  git -C data/www/TOOLS/Opcache-gui pull origin master
  git -C data/www/TOOLS/Xdebug-trace pull origin master
  git -C data/www/TOOLS/adminerExtended pull origin master
  git -C data/www/TOOLS/phpRedisAdmin pull origin master
  git -C data/www/TOOLS/phpRedisAdmin/vendor pull origin master
elif [[ $1 == 'delete' ]]
then
  rm -rf data/www/TOOLS/PimpMyLog
  rm -rf data/www/TOOLS/PhpMemcachedAdmin
  rm -rf data/www/TOOLS/Opcache-gui
  rm -rf data/www/TOOLS/Xdebug-trace
  rm -rf data/www/TOOLS/adminerExtended
  rm -rf data/www/TOOLS/phpRedisAdmin
else
  git clone https://github.com/potsky/PimpMyLog.git data/www/TOOLS/PimpMyLog
  cp config/pimpmylog/config.user.php data/www/TOOLS/PimpMyLog/config.user.php
  git clone https://github.com/wp-cloud/phpmemcacheadmin.git data/www/TOOLS/PhpMemcachedAdmin
  cp config/memcache/Memcache.php data/www/TOOLS/PhpMemcachedAdmin/Config/Memcache.php
  git clone https://github.com/amnuts/opcache-gui.git data/www/TOOLS/Opcache-gui
  git clone https://github.com/splitbrain/xdebug-trace-tree.git data/www/TOOLS/Xdebug-trace
  git clone https://github.com/dg/adminer-custom.git data/www/TOOLS/adminerExtended
  git clone https://github.com/ErikDubbelboer/phpRedisAdmin.git data/www/TOOLS/phpRedisAdmin
  git clone https://github.com/nrk/predis.git data/www/TOOLS/phpRedisAdmin/vendor
  cp config/redis/config.inc.php data/www/TOOLS/phpRedisAdmin/includes/config.inc.php
fi
