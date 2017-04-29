#! /bin/bash

# This script is an helper to setup this Drupal 8 with composer on Ubuntu 16.04.
# This script must be run as root, it should be run after sample-setup.sh in this folder.

# Variables.
project_path="/home/ubuntu/docker-compose-drupal"
project_container_apache="dockercomposedrupal_apache_1"
project_root="$project_path/data/www"
project_container_root="/www/drupal8"
drush_bin="$project_container_root/vendor/bin/drush"
drush_root="--root=$project_container_root/web"
drush_options="--db-url=mysql://drupal:drupal@mysql/drupal --account-pass=password"

# As we are root, we need this to use composer.
export COMPOSER_HOME=/home/ubuntu/.composer
# Setup Drupal 8 composer project.
/usr/local/bin/composer create-project drupal-composer/drupal-project:8.x-dev $project_root/drupal8 --stability dev --no-interaction
/usr/local/bin/composer -d=$project_root/drupal8 require "drupal/devel" "drupal/admin_toolbar"

# Set-up Drupal.
echo "[setup::info] Install Drupal 8..."
docker exec -t --user apache $project_container_apache $drush_bin $drush_root -y site-install $drush_options >> drupal-si.log
docker exec -t --user apache $project_container_apache $drush_bin $drush_root -y en admin_toolbar >> /dev/null

echo -e ">>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>\n"
echo -e "[setup::info] Drupal 8 installed, account: admin, password: password\n"
echo -e "<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<\n"
