#! /bin/bash

# This script is an helper to setup this Drupal 8 with composer on Ubuntu 16.04.
# This script must be run as ubuntu user with sudo privileges. From cloud-init
# Ubuntu user should be a sudoers without password. Should be used after a setup script
# from this folder.

# Variables.
project_path="$HOME/docker-compose-drupal"
project_container_apache="dockercomposedrupal_apache_1"
project_root="$project_path/data/www"
project_container_root="/www/drupal8"
drush_bin="$project_container_root/vendor/bin/drush"
drush_root="--root=$project_container_root/web"
drush_options="--db-url=mysql://drupal:drupal@mysql/drupal --account-pass=password"

# Setup Drupal 8 composer project.
/usr/local/bin/composer create-project drupal-composer/drupal-project:8.x-dev $project_root/drupal8 --stability dev --no-interaction
/usr/local/bin/composer -d=$project_root/drupal8 require "drupal/devel" "drupal/admin_toolbar"

# Set-up Drupal.
echo "[setup::info] Install Drupal 8..."
#docker exec -t $project_container_apache chown -R apache: /www
docker exec -t --user apache $project_container_apache $drush_bin $drush_root -y site-install $drush_options >> $project_path/drupal-install.log
docker exec -t --user apache $project_container_apache $drush_bin $drush_root -y en admin_toolbar >> /dev/null

# Add project variables to environment.
cat <<EOT >> /home/ubuntu/.profile
PROJECT_PATH="$project_root/drupal8"
PROJECT_CONTAINER_PATH="$project_container_root"
DRUSH_CONTAINER_BIN="$project_container_root/vendor/bin/drush"
DRUSH_CONTAINER_ROOT="--root=$project_container_root/web"
EOT

echo -e ">>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>\n"
echo -e "[setup::info] Drupal 8 installed, account: admin, password: password\n"
echo -e "<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<\n"