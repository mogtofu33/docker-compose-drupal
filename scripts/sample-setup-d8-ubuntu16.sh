#! /bin/bash

# This script is an helper to setup this Drupal 8 with composer on Ubuntu 16.04.
# This script must be run as ubuntu user with sudo privileges. From cloud-init
# Ubuntu user should be a sudoers without password. Should be used after a setup script
# from this folder.

# Variables, should be cleaned as we use a setup script before this one.
project_path="$HOME/docker-compose-drupal"
project_container_apache="dockercomposedrupal_apache_1"
project_root="$project_path/data/www"
project_container_root="/www/drupal"
project_container_web_root="$project_container_root/web"
drupal_bin="$project_container_root/vendor/bin/drupal"
drush_bin="$project_container_root/vendor/bin/drush"
drush_root="--root=$project_container_web_root"
drush_options="--db-url=mysql://drupal:drupal@mysql/drupal --account-pass=password"

# Setup Drupal 8 composer project.
/usr/local/bin/composer create-project drupal-composer/drupal-project:8.x-dev $project_root/drupal --stability dev --no-interaction
/usr/local/bin/composer -d=$project_root/drupal require "drupal/devel" "drupal/admin_toolbar"

# Set-up Drupal.
echo "[setup::info] Install Drupal 8..."
#docker exec -t $project_container_apache chown -R apache: /www
docker exec -t --user apache $project_container_apache $drush_bin $drush_root -y site-install $drush_options >> $project_path/drupal-install.log
docker exec -t --user apache $project_container_apache $drush_bin $drush_root -y en admin_toolbar >> /dev/null

# Add project variables to environment.
cat <<EOT >> /home/ubuntu/.profile
DRUSH_CONTAINER_BIN="$project_container_root/vendor/bin/drush"
DRUSH_CONTAINER_ROOT="--root=$project_container_root/web"
EOT

# Add drush and drupal bin shortcut.
sudo touch /usr/local/bin/drush
sudo touch /usr/local/bin/drupal
sudo chown ubuntu:ubuntu /usr/local/bin/drush /usr/local/bin/drupal
sudo chmod +x /usr/local/bin/drush /usr/local/bin/drupal
cat <<EOT > /usr/local/bin/drush
#!/bin/bash
# Drush within Docker, should be used with aliases.
docker exec -it --user apache $project_container_apache $drush_bin $@
EOT

cat <<EOT > /usr/local/bin/drush
#!/bin/bash
# Drupal console within Docker.
docker exec -it --user apache $project_container_apache bash -c 'cd $project_container_web_root; $drupal_bin \$1' -- "\$@"
EOT

echo -e ">>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>\n"
echo -e "[setup::info] Drupal 8 installed, account: admin, password: password\n"
echo -e "<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<\n"
