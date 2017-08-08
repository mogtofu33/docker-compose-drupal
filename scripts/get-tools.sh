#!/bin/bash

# Helper to get third party tools, must be run from parent folder.

SOURCE="${BASH_SOURCE[0]}"
BASENAME=`basename $0`

if [[ $SOURCE != "./$BASENAME" ]]; then
  echo -e "This script must be run from the scripts folder of this project:"
  echo -e "cd scripts"
  echo -e "./$BASENAME"
  exit;
fi

if [[ $1 == 'update' ]]
then
  git -C ./../tools/PimpMyLog pull origin master
  git -C ./../tools/PhpMemcachedAdmin pull origin master
  git -C ./../tools/Opcache-gui pull origin master
  git -C ./../tools/Xdebug-trace pull origin master
  git -C ./../tools/adminerExtended pull origin master
  git -C ./../tools/phpRedisAdmin pull origin master
  git -C ./../tools/phpRedisAdmin/vendor pull origin master
elif [[ $1 == 'delete' ]]
then
  rm -rf ./../tools/PimpMyLog
  rm -rf ./../tools/PhpMemcachedAdmin
  rm -rf ./../tools/Opcache-gui
  rm -rf ./../tools/Xdebug-trace
  rm -rf ./../tools/adminerExtended
  rm -rf ./../tools/phpRedisAdmin
else
  git clone https://github.com/potsky/PimpMyLog.git ./../tools/PimpMyLog
  cp ./../config/pimpmylog/config.user.php ./../tools/PimpMyLog/config.user.php
  git clone https://github.com/wp-cloud/phpmemcacheadmin.git ./../tools/PhpMemcachedAdmin
  cp ./../config/memcache/Memcache.php ./../tools/PhpMemcachedAdmin/Config/Memcache.php
  git clone https://github.com/amnuts/opcache-gui.git ./../tools/Opcache-gui
  git clone https://github.com/splitbrain/xdebug-trace-tree.git ./../tools/Xdebug-trace
  git clone https://github.com/dg/adminer-custom.git ./../tools/adminerExtended
  git clone https://github.com/ErikDubbelboer/phpRedisAdmin.git ./../tools/phpRedisAdmin
  git clone https://github.com/nrk/predis.git ./../tools/phpRedisAdmin/vendor
  cp ./../config/redis/config.inc.php ./../tools/phpRedisAdmin/includes/config.inc.php
fi
