#! /bin/bash

# This script is an helper to setup this docker compose Drupal stack on Ubuntu 16.04.
# This script must be run as root, it can be run from a cloud-config init.

SCRIPT_DIR="$(dirname "$0")"

# Variables.
project_path="/home/ubuntu/docker-compose-drupal"
project_container_apache="dockercomposedrupal_apache_1"
project_root="$project_path/data/www"
docker_compose_version="1.12.0"
docker_stack_repo="https://github.com/Mogtofu33/docker-compose-drupal.git"

# Ensure ubuntu user is created.
mkdir -p /home/ubuntu/

# Setup docker-compose.
if [ ! -f "/usr/local/bin/docker-compose" ]; then
  echo "[setup::info] 1/4 Set-up Docker compose..."
  wget -q "https://github.com/docker/compose/releases/download/$docker_compose_version/docker-compose-Linux-x86_64"
  mv docker-compose-Linux-x86_64 /usr/local/bin/docker-compose
  chmod +x /usr/local/bin/docker-compose
else
  echo "[setup::info] Docker compose already here"
fi

# Get a Docker compose stack (Apache/Php/Mysql/Mailhog/Solr).
if [ ! -d "$project_path" ]; then
  echo "[setup::info] 2/4 Set-up Docker stack..."
  git clone $docker_stack_repo $project_path
  # set up tools from stack
  cd $project_path;
  ./scripts/get-tools.sh
  chown -R ubuntu: $project_path
else
  echo "[setup::info] Docker stack already here!"
fi

# Set-up composer.
if [ ! -f "/usr/local/bin/composer" ]; then
  echo "[setup::info] 3/4 Set-up Composer and dependencies..."
  mkdir -p /home/ubuntu/.composer
  export COMPOSER_HOME=/home/ubuntu/.composer
  curl -sS https://getcomposer.org/installer | php -- --filename=composer
  mv composer /usr/local/bin/composer
  chmod +x /usr/local/bin/composer
  /usr/local/bin/composer global require "hirak/prestissimo:^0.3" "drupal/coder"
  export PATH="$PATH:$COMPOSER_HOME/vendor/bin"
else
  echo "[setup::info] Composer already here!"
  ## Install dependencies just in case.
  /usr/local/bin/composer global require "hirak/prestissimo:^0.3" "drupal/coder"
fi

# Set-up Code sniffer.
$COMPOSER_HOME/vendor/bin/phpcs --config-set installed_paths $COMPOSER_HOME/vendor/drupal/coder/coder_sniffer

# Set-up this Docker compose stack.
echo "[setup::info] 4/4 First time Docker stack up, pull images and set-up tools..."
cp $project_path/default.env $project_path/.env
cp $project_path/docker-compose.tpl.yml $project_path/docker-compose.yml
# Fix permissions (we are root when running this script).
chown -R ubuntu:ubuntu $project_path
cd $project_path
docker-compose up

# Wait for containers to be up...
RUNNING=$(docker inspect --format="{{ .State.Running }}" $project_container_apache 2> /dev/null)
if [ $? -eq 1 ]; then
  echo "[setup::ERROR] Container $project_container_apache does not exist..."
  # Wait a bit....
  sleep 20s
fi

# Convenient links.
ln -s $project_root /home/ubuntu/www
ln -s $project_path /home/ubuntu/root

# Fix permissions (we are root when running this script).
chown -R ubuntu:ubuntu /home/ubuntu

echo -e ">>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>\n"
echo -e "[setup::info] Install finished!\n"
echo -e "<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<\n"
