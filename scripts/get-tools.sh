#! /bin/bash

if [[ $1 == 'update' ]]; then
  git -C data/www/TOOLS/PimpMyLog pull origin master
  git -C data/www/TOOLS/PhpMemcachedAdmin pull origin master
  git -C data/www/TOOLS/Opcache-gui pull origin master
  git -C data/www/TOOLS/Xdebug-trace pull origin master
  git -C data/www/TOOLS/adminer pull origin master
else
  git clone https://github.com/potsky/PimpMyLog.git data/www/TOOLS/PimpMyLog
  cp config/pimpmylog data/www/TOOLS/PimpMyLog/config.user.php
  git clone https://github.com/wp-cloud/phpmemcacheadmin.git data/www/TOOLS/PhpMemcachedAdmin
  git clone https://github.com/amnuts/opcache-gui.git data/www/TOOLS/Opcache-gui
  git clone https://github.com/splitbrain/xdebug-trace-tree.git data/www/TOOLS/Xdebug-trace
  git clone https://github.com/dg/adminer-custom.git data/www/TOOLS/adminer
fi
