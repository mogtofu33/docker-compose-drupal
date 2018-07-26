#!/bin/bash

# This script is an helper to setup A Bootstrap Sass subtheme on Drupal 8.
# It must be run as ubuntu user with sudo privileges. Ubuntu user must be a
# sudoers without password. Should be used after a setup script from this folder
# has created a Drupal 8 instance.
# This script is used with a cloud config setup from this folder.
# For Sass support on Ubuntu 16.04/18.04 you need
#   ruby-full ruby-compass ruby-sass ruby-bootstrap-sass

# Variables, most variables are from previous script.
source $HOME/.profile

# Base variables for this script, can be edited.
name="bootstrap_sass"
title="Bootstrap Sass"
bootstrap_version="3.3.7"
config_rb="https://gist.githubusercontent.com/Mogtofu33/c8bd086d12a6b6540763610893da5364/raw/fcfa4d4a15dbb45b5b6f8fc70f4d0a4bef8081f5/config_dev.rb"

# Cmd and path variables.
theme="$PROJECT_ROOT/drupal/web/themes"

# Add Bootstrap theme of Drupal 8 with composer.
echo -e "\n>>>>\n[setup::info] Install Bootstrap for Drupal 8...\n<<<<\n"
/usr/bin/composer --working-dir=${PROJECT_ROOT}/drupal require "drupal/bootstrap:^3"

# Create bootstrap subtheme.
# see https://drupal-bootstrap.org/api/bootstrap/starterkits%21sass%21README.md/group/sub_theming_sass/8
echo -e "\n>>>>\n[setup::info] Create $title subtheme...\n<<<<\n"
mkdir -p $theme/custom
cp -r $theme/contrib/bootstrap/starterkits/sass/ $theme/custom/$name

# Copy and adpat config to get a default block position.
cp -r $theme/contrib/bootstrap/config/optional/ $theme/custom/$name/config/
for i in $theme/custom/$name/config/optional/*.yml; do
  new_file=$(echo $i | sed "s/block\.bootstrap\_/block\.${name}\_/g");
  mv $i $new_file;
  sed -i -e "s/id: bootstrap_/id: ${name}_/g" $new_file;
  sed -i -e "s/theme: bootstrap/theme: ${name}/g" $new_file;
  sed -i -e "s/\- bootstrap/\- ${name}/g" $new_file;
done

# Get Bootstrap sass source.
wget -q -O $theme/custom/$name/$bootstrap_version.tar.gz https://github.com/twbs/bootstrap-sass/archive/v$bootstrap_version.tar.gz
tar -xvzf $theme/custom/$name/$bootstrap_version.tar.gz -C $theme/custom/$name/
mv $theme/custom/$name/bootstrap-sass-$bootstrap_version $theme/custom/$name/bootstrap
rm -f $theme/custom/$name/$bootstrap_version.tar.gz
mv $theme/custom/$name/THEMENAME.starterkit.yml $theme/custom/$name/$name.info.yml
mv $theme/custom/$name/THEMENAME.libraries.yml $theme/custom/$name/$name.libraries.yml
mv $theme/custom/$name/THEMENAME.theme $theme/custom/$name/$name.theme
mv $theme/custom/$name/config/install/THEMENAME.settings.yml $theme/custom/$name/config/install/$name.settings.yml
mv $theme/custom/$name/config/schema/THEMENAME.schema.yml $theme/custom/$name/config/schema/$name.schema.yml

# We need a config file for compiling.
wget -q -O $theme/custom/$name/config.rb $config_rb

# Locally edit files.
sed -i -e "s/THEMETITLE/${title}/g" $PROJECT_ROOT/drupal/web/themes/custom/$name/$name.info.yml
sed -i -e "s/THEMENAME/${name}/g" $PROJECT_ROOT/drupal/web/themes/custom/$name/$name.info.yml
sed -i -e "s/THEMETITLE/${title}/g" $PROJECT_ROOT/drupal/web/themes/custom/$name/config/schema/$name.schema.yml
sed -i -e "s/THEMENAME/${name}/g" $PROJECT_ROOT/drupal/web/themes/custom/$name/config/schema/$name.schema.yml

# Compass compile.
if [ -f "/usr/bin/compass" ]; then
  /usr/bin/compass compile $PROJECT_ROOT/drupal/web/themes/custom/$name
else
  echo -e "\n>>>>\n[setup::warning] could not find compass and compile $PROJECT_ROOT/drupal/web/themes/custom/$name\n<<<<\n"
fi

# Run drush commands to enable this theme with drush bin from previous script (setup_DCD_D8_ubuntu.sh).
echo -e "\n>>>>\n[setup::info] Enable $title subtheme...\n<<<<\n"
if [ -f "/usr/local/bin/drush" ]; then
  docker exec -t --user apache $PROJECT_CONTAINER_NAME $DRUSH_BIN $DRUSH_ROOT -y theme:enable bootstrap
  docker exec -t --user apache $PROJECT_CONTAINER_NAME $DRUSH_BIN $DRUSH_ROOT -y theme:enable $name
  docker exec -t --user apache $PROJECT_CONTAINER_NAME $DRUSH_BIN $DRUSH_ROOT -y cset system.theme default $name
else
  echo -e "\n>>>>\n[setup::warning] could not find drush and enable $title\n<<<<\n"
fi

echo -e "\n>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>\n
[setup::info] Bootstrap Sass subtheme installed!\n
<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<\n"
