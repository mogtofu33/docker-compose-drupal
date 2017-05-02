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
  echo "[setup::info] 1/5 Set-up Docker compose $docker_compose_version..."
  sudo wget -O /usr/local/bin/docker-compose "https://github.com/docker/compose/releases/download/$docker_compose_version/docker-compose-Linux-x86_64"
  sudo chmod +x /usr/local/bin/docker-compose
else
  echo "[setup::info] 1/5 Docker compose already here"
fi

# Get a Docker compose stack (Apache/Php/Mysql/Mailhog/Solr).
if [ ! -d "$project_path" ]; then
  echo "[setup::info] 2/5 Clone Docker stack and tools..."
  git clone $docker_stack_repo $project_path
  # set up tools from stack
  cd $project_path;
  ./scripts/get-tools.sh
else
  echo "[setup::info] 2/5 Docker stack already here!"
fi

# Set-up and launch this Docker compose stack.
echo "[setup::info] 3/5 Prepare Docker stack and set-up tools..."
cp $project_path/default.env $project_path/.env
# Default file is Apache/Mysql/Memcache/Solr/Mailhog.
cp $project_path/docker-compose.tpl.yml $project_path/docker-compose.yml
cd $project_path
docker-compose up -d

# Set-up composer.
if [ ! -f "/usr/local/bin/composer" ]; then
  echo "[setup::info] 4/5 Set-up Composer and dependencies..."
  mkdir -p /home/ubuntu/.composer
  export COMPOSER_HOME=/home/ubuntu/.composer
  curl -sS https://getcomposer.org/installer | php -- --filename=composer
  sudo mv composer /usr/local/bin/composer
  sudo chmod +x /usr/local/bin/composer
  /usr/local/bin/composer global require "hirak/prestissimo:^0.3" "drupal/coder"
  echo "COMPOSER_HOME=/home/ubuntu/.composer" >> /home/ubuntu/.profile
  echo "PATH=\$PATH:/home/ubuntu/.composer/vendor/bin" >> /home/ubuntu/.profile
else
  echo "[setup::info] Composer already here!"
  ## Install dependencies just in case.
  /usr/local/bin/composer global require "hirak/prestissimo:^0.3" "drupal/coder"
fi

# Set-up Code sniffer.
echo "[setup::info] 5/5 Set-up Code sniffer and final steps..."
$COMPOSER_HOME/vendor/bin/phpcs --config-set installed_paths $COMPOSER_HOME/vendor/drupal/coder/coder_sniffer

# Check if containers are up...
RUNNING=$(docker inspect --format="{{ .State.Running }}" $project_container_apache 2> /dev/null)
if [ $? -eq 1 ]; then
  echo "[setup::ERROR] Container $project_container_apache does not exist..."
  # Wait a bit for stack to be up....
  sleep 30s
fi

# Add project variables to environment.
cat <<EOT >> /home/ubuntu/.profile
# Docker stack variables.
PROJECT_PATH="$project_path"
PROJECT_ROOT="$project_path/data/www"
PROJECT_CONTAINER_NAME="$project_container_apache"
EOT

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
# Command within Docker.
alias dcmd="docker exec -it --user apache $project_container_apache"
EOT

# Convenient links.
ln -s $project_root /home/ubuntu/www
sudo ln -s $project_root /www
sudo chown ubuntu: /www
ln -s $project_path /home/ubuntu/root

echo -e ">>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>\n"
echo -e "[setup::info] Install finished!\n"
echo -e "<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<\n"
