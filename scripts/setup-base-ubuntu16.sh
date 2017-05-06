#!/bin/bash

# This is an helper to setup Docker Compose, Composer and Code sniffer on
# Ubuntu 16.04.
# This script must be run as ubuntu user with sudo privileges.

# Variables for versions.
docker_compose_version="1.12.0"

# Fix permissions.
sudo chown -R ubuntu:ubuntu /home/ubuntu

# Setup docker-compose.
if [ ! -f "/usr/local/bin/docker-compose" ]; then
  echo "[setup::info] Set-up Docker compose $docker_compose_version..."
  sudo wget -O /usr/local/bin/docker-compose "https://github.com/docker/compose/releases/download/$docker_compose_version/docker-compose-Linux-x86_64"
  sudo chown ubuntu:ubuntu /usr/local/bin/docker-compose
  sudo chmod +x /usr/local/bin/docker-compose
else
  echo "[setup::info] Docker compose already here"
fi

# Set-up composer.
if [ ! -f "/usr/local/bin/composer" ]; then
  echo "[setup::info] Set-up Composer and dependencies..."
  curl -sS https://getcomposer.org/installer | php -- --install-dir=/home/ubuntu/ --filename=composer
  sudo mv /home/ubuntu/composer /usr/local/bin/composer
  sudo chmod +x /usr/local/bin/composer
  /usr/local/bin/composer global require "hirak/prestissimo:^0.3" "drupal/coder"
  echo "PATH=\$PATH:/home/ubuntu/.config/composer/vendor/bin" >> /home/ubuntu/.profile
else
  echo "[setup::info] Composer already here!"
  ## Install dependencies just in case.
  /usr/local/bin/composer global require "hirak/prestissimo:^0.3" "drupal/coder"
fi

# Set-up Code sniffer.
if [ ! -f "/usr/local/bin/composer" ]; then
echo "[setup::info] Set-up Code sniffer and final steps..."
/home/ubuntu/.config/composer/vendor/bin/phpcs --config-set installed_paths /home/ubuntu/.config/composer/vendor/drupal/coder/coder_sniffer

# Add drush alias shortcut.
cat <<EOT >> /home/ubuntu/.bash_aliases
# Docker
alias dk='docker'
# Docker-compose
alias dkc='docker-compose'
# Check Drupal coding standards
alias drcs="phpcs --standard=Drupal --extensions='php,module,inc,install,test,profile,theme,js,css,info,txt'"
# Check Drupal best practices
alias drcsbp="phpcs --standard=DrupalPractice --extensions='php,module,inc,install,test,profile,theme,js,css,info,txt,md'"
# Fix Drupal coding standards
alias drcsfix="phpcbf --standard=Drupal --extensions='php,module,inc,install,test,profile,theme,js,css,info,txt'"
EOT

mkdir -p /home/ubuntu/www

echo -e ">>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>\n"
echo -e "[setup::info] Install finished!\n"
echo -e "<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<\n"
