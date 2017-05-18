#!/bin/bash

# This script is an helper to setup this Drupal 8 with composer on Ubuntu 16.04.
# This script must be run as ubuntu user with sudo privileges without password.
# This script is used with a cloud config setup from this folder.

# Variables, some variables are from previous script.
source $HOME/.profile
project_container_root="$PROJECT_ROOT/drupal"
project_container_web_root="$project_container_root/web"
drupal_bin="$project_container_root/vendor/bin/drupal"
drush_bin="$project_container_root/vendor/bin/drush"
drush_root="--root=$project_container_root/web"
drush_options="--db-url=mysql://drupal:drupal@mysql/drupal --account-pass=password"

# Setup Drupal 8 composer project.
/usr/local/bin/composer create-project drupal-composer/drupal-project:8.x-dev $project_container_root --stability dev --no-interaction
/usr/local/bin/composer -d=$project_container_root require "drupal/devel" "drupal/admin_toolbar"

# Set-up Drupal.
echo "[setup::info] Install Drupal 8..."
#docker exec -t $PROJECT_CONTAINER_NAME chown -R apache: /www
docker exec -t --user apache $PROJECT_CONTAINER_NAME $drush_bin $drush_root -y site-install $drush_options >> $PROJECT_PATH/drupal-install.log
docker exec -t --user apache $PROJECT_CONTAINER_NAME $drush_bin $drush_root -y en admin_toolbar >> /dev/null

# Add project variables to environment.
cat <<EOT >> $HOME/.profile
DRUSH_CONTAINER_BIN="$project_container_root/vendor/bin/drush"
DRUSH_CONTAINER_ROOT="--root=$project_container_web_root"
EOT

# Add drush and drupal bin shortcut.
sudo touch /usr/local/bin/drush
sudo touch /usr/local/bin/drupal
sudo chown ubuntu:ubuntu /usr/local/bin/drush /usr/local/bin/drupal
sudo chmod +x /usr/local/bin/drush /usr/local/bin/drupal
cat <<EOT > /usr/local/bin/drush
#!/bin/bash
# Drush within Docker, should be used with aliases.
docker exec -it --user apache $PROJECT_CONTAINER_NAME $drush_bin \$@
EOT

cat <<EOT > /usr/local/bin/drupal
#!/bin/bash
# Drupal console within Docker.
cmd="$drupal_bin \$@"
docker exec -it --user apache $PROJECT_CONTAINER_NAME bash -c 'cd '"$project_container_web_root"'; \$1' -- "\$cmd"
EOT

echo -e ">>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>\n"
echo -e "[setup::info] Drupal 8 installed, account: admin, password: password\n"
echo -e "<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<\n"
