#!/bin/bash

# This script is an helper to setup this Drupal 8 with composer on Ubuntu 16.04.
# This script must be run as ubuntu user with sudo privileges without password.
# This script is used with a cloud config setup from this folder.

# Variables, most variables are from previous script.
source $HOME/.profile

drush_options="--db-url=mysql://drupal:drupal@mysql/drupal --account-pass=password"

# Setup Drupal 8 composer project.
/usr/bin/composer create-project drupal-composer/drupal-project:8.x-dev $PROJECT_ROOT/drupal --stability dev --no-interaction
/usr/bin/composer -d=$PROJECT_ROOT/drupal require "drupal/devel" "drupal/admin_toolbar"

# Set-up Drupal.
echo "[setup::info] Install Drupal 8..."
#docker exec -t $PROJECT_CONTAINER_NAME chown -R apache: /www
docker exec -t --user apache $PROJECT_CONTAINER_NAME $DRUSH_BIN $DRUSH_ROOT -y site-install $drush_options >> $PROJECT_PATH/drupal-install.log
docker exec -t --user apache $PROJECT_CONTAINER_NAME $DRUSH_BIN $DRUSH_ROOT -y en admin_toolbar >> /dev/null

# Add project variables to environment.
cat <<EOT >> $HOME/.profile
DRUSH_CONTAINER_BIN="$DRUSH_BIN"
DRUSH_CONTAINER_ROOT="--root=$PROJECT_CONTAINER_WEB_ROOT"
EOT

# Add drush and drupal bin shortcut.
sudo touch /usr/local/bin/drush
sudo touch /usr/local/bin/drupal
sudo chown ubuntu:ubuntu /usr/local/bin/drush /usr/local/bin/drupal
sudo chmod +x /usr/local/bin/drush /usr/local/bin/drupal
cat <<EOT > /usr/local/bin/drush
#!/bin/bash
# Drush within Docker, should be used with aliases.
docker exec -it --user apache $PROJECT_CONTAINER_NAME $DRUSH_BIN \$@
EOT

cat <<EOT > /usr/local/bin/drupal
#!/bin/bash
# Drupal console within Docker.
cmd="$DRUPAL_BIN \$@"
docker exec -it --user apache $PROJECT_CONTAINER_NAME bash -c 'cd '"$PROJECT_CONTAINER_WEB_ROOT"'; \$1' -- "\$cmd"
EOT

echo -e ">>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>\n"
echo -e "[setup::info] Drupal 8 installed, account: admin, password: password\n"
echo -e "<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<\n"
