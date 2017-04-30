#! /bin/bash

# This is an helper to setup this docker compose Drupal stack on Ubuntu 16.04.
# This script must be run as ubuntu user with sudo privileges. From cloud-init
# Ubuntu user should be a sudoers without password.

# Variables.
docker_compose_version="1.12.0"
docker_stack_repo="https://github.com/Mogtofu33/docker-compose-drupal.git"
project_path="$HOME/docker-compose-drupal"
project_container_apache="dockercomposedrupal_apache_1"
project_root="$project_path/data/www"

# Setup docker-compose.
if [ ! -f "/usr/local/bin/docker-compose" ]; then
  echo "[setup::info] 1/6 Set-up Docker compose $docker_compose_version..."
  wget -q "https://github.com/docker/compose/releases/download/$docker_compose_version/docker-compose-Linux-x86_64"
  sudo mv docker-compose-Linux-x86_64 /usr/local/bin/docker-compose
  sudo chmod +x /usr/local/bin/docker-compose
else
  echo "[setup::info] 1/6 Docker compose already here"
fi

# Get a Docker compose stack (Apache/Php/Mysql/Mailhog/Solr).
if [ ! -d "$project_path" ]; then
  echo "[setup::info] 2/6 Clone Docker stack and tools..."
  git clone $docker_stack_repo $project_path
  # set up tools from stack
  cd $project_path;
  ./scripts/get-tools.sh
else
  echo "[setup::info] 2/6 Docker stack already here!"
fi

# Set-up and launch this Docker compose stack.
echo "[setup::info] 3/6 Prepare Docker stack and set-up tools..."
cp $project_path/default.env $project_path/.env
# Default file is Apache/Mysql/Memcache/Solr/Mailhog.
cp $project_path/docker-compose.tpl.yml $project_path/docker-compose.yml
cd $project_path
docker-compose up -d

# Set-up composer.
if [ ! -f "/usr/local/bin/composer" ]; then
  echo "[setup::info] 5/6 Set-up Composer and dependencies..."
  curl -sS https://getcomposer.org/installer | php -- --filename=composer
  sudo mv composer /usr/local/bin/composer
  sudo chmod +x /usr/local/bin/composer
  /usr/local/bin/composer global require "hirak/prestissimo:^0.3" "drupal/coder"
else
  echo "[setup::info] Composer already here!"
  ## Install dependencies just in case.
  /usr/local/bin/composer global require "hirak/prestissimo:^0.3" "drupal/coder"
fi

# Set-up Code sniffer.
echo "[setup::info] 6/6 Set-up Code sniffer and final steps..."
$COMPOSER_HOME/vendor/bin/phpcs --config-set installed_paths $COMPOSER_HOME/vendor/drupal/coder/coder_sniffer

# Check if containers are up...
RUNNING=$(docker inspect --format="{{ .State.Running }}" $project_container_apache 2> /dev/null)
if [ $? -eq 1 ]; then
  echo "[setup::ERROR] Container $project_container_apache does not exist..."
  # Wait a bit for stack to be up....
  sleep 30s
fi

# Convenient links.
ln -s $project_root /home/ubuntu/www
ln -s $project_path /home/ubuntu/root

echo -e ">>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>\n"
echo -e "[setup::info] Install finished!\n"
echo -e "<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<\n"
