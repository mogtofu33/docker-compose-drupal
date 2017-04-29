#! /bin/bash

# This script is an helper to setup this Drupal 8 with composer on Ubuntu 16.04.
# This script must be run as root, it should be run after sample-setup.sh in this folder.

SCRIPT_DIR="$(dirname "$0")"

# Variables.
project_path="/home/ubuntu/docker-compose-drupal"
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
docker exec -t --user apache $project_container_apache $drush_bin $drush_root -y site-install $drush_options
