#!/bin/bash

# This script is an helper to setup A Bootstrap Sass subtheme on Drupal 8.
# This script must be run as ubuntu user with sudo privileges. From cloud-init
# Ubuntu user should be a sudoers without password. Should be used after a setup script
# from this folder has created a Drupal 8 instance.

# Base variables for this script.
bootstrap_version="3.3.7"
docker_cmd="docker exec -t --user apache $project_container_apache "
name="bootstrap_sass"
title="Bootstrap Sass"


# these variables should be cleaned as we use a setup script before this one.
project_path="$HOME/docker-compose-drupal"
project_container_apache="dockercomposedrupal_apache_1"
project_root="$project_path/data/www"
project_container_root="/www/drupal"
project_container_web_root="$project_container_root/web"
theme="$project_container_web_root/web/theme"
drupal_bin="$project_container_root/vendor/bin/drupal"
drush_bin="$project_container_root/vendor/bin/drush"
drush_root="--root=$project_container_web_root"

# Add Bootstrap theme of Drupal 8 with composer.
echo "[setup::info] Install Bootstrap for Drupal 8..."
/usr/local/bin/composer -d=$project_root/drupal require "drupal/bootstrap"

# Create bootstrap subtheme
echo "[setup::info] Create $title subtheme..."
$docker_cmd mkdir -p $theme/custom
$docker_cmd cp -r $theme/contrib/bootstrap/starterkits/sass $theme/custom/$name
$docker_cmd wget -O $theme/custom/$name/$bootstrap_version.tar.gz https://github.com/twbs/bootstrap-sass/archive/v$bootstrap_version.tar.gz
$docker_cmd tar -xvzf $theme/custom/$name/$bootstrap_version.tar.gz -C $theme/custom/$name/
$docker_cmd mv $theme/custom/$name/bootstrap-sass-$bootstrap_version $theme/custom/$name/bootstrap
$docker_cmd rm -f $theme/custom/$name/$bootstrap_version.tar.gz
$docker_cmd mv $theme/custom/$name/THEMENAME.starterkit.yml $theme/custom/$name/$name.info.yml
$docker_cmd mv $theme/custom/$name/THEMENAME.libraries.yml $theme/custom/$name/$name.libraries.yml
$docker_cmd mv $theme/custom/$name/THEMENAME.theme $theme/custom/$name/$name.theme
$docker_cmd mv $theme/custom/$name/config/install/THEMENAME.settings.yml $theme/custom/$name/config/install/$name.settings.yml
$docker_cmd mv $theme/custom/$name/config/schema/THEMENAME.schema.yml $theme/custom/$name/config/schema/$name.schema.yml
$docker_cmd wget -O $theme/custom/$name/config.rb https://gist.githubusercontent.com/Mogtofu33/99a6a764ce0be20d7faa55c7ed315def/raw/18c33d42f539877bf52df4704ecf293e88e7bdfb/config.rb

# Locally edit files.
sed -i -e 's/THEMETITLE/$title/g' $project_root/drupal/web/themes/custom/$name/$name.info.yml
sed -i -e 's/THEMENAME/$name/g' $project_root/drupal/web/themes/custom/$name/$name.info.yml
sed -i -e 's/THEMETITLE/$title/g' $project_root/drupal/web/themes/custom/$name/config/schema/$name.schema.yml
sed -i -e 's/THEMENAME/$name/g' $project_root/drupal/web/themes/custom/$name/config/schema/$name.schema.yml

# Compass compile
compass compile $project_root/drupal/web/themes/custom/$name

# Run drush commands to enable this theme.
echo "[setup::info] Enable $title subtheme..."
$docker_cmd $drush_bin $drush_root -y en bootstrap
$docker_cmd $drush_bin $drush_root -y en bootstrap_sass
$docker_cmd $drush_bin $drush_root -y config-set system.theme default bootstrap_sass

echo -e ">>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>\n"
echo -e "[setup::info] Bootstrap Sass subtheme installed!\n"
echo -e "<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<\n"
