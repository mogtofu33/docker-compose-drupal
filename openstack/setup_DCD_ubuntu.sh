#!/bin/bash

# This is an helper to setup this docker compose Drupal stack on Ubuntu 16.04/18.04.
# This script must be run as ubuntu user with sudo privileges without password.
# We assume that docker and docker-compose is properly installed when using this
# script (From cloud config files in this folder).
# This script is used with a cloud config setup from this folder.

# Variables.
_USER="ubuntu"
_GROUP="ubuntu"

# Project variables.
_REPO="https://github.com/Mogtofu33/docker-compose-drupal.git"
_BRANCH=${1-"master"}
_BASE=${2-"default"}
_PROJECT_PATH="$HOME/docker-compose-drupal"
_PHP="dcd-php"
_PROJECT_ROOT="$_PROJECT_PATH/data/www"
_ROOT="/var/www/localhost/drupal"
_WEB="$_ROOT/web"
_DRUPAL_CONSOLE="$_ROOT/vendor/bin/drupal"
_DRUSH="$_ROOT/vendor/bin/drush"

# Fix permissions.
sudo chown -R $_USER:$_GROUP $HOME

# Set Docker group to our user.
sudo usermod -a -G docker $_USER

# Get a Docker compose stack.
if [ ! -d "$_PROJECT_PATH" ]; then
  echo -e "\n>>>>\n[setup::info] Clone Docker stack...\n<<<<\n"
  git clone -b $_BRANCH $_REPO $_PROJECT_PATH
else
  echo -e "\n>>>>\n[setup::notice] Docker stack already here!\n<<<<\n"
fi

# Set-up and launch this Docker compose stack.
echo -e "\n>>>>\n[setup::info] Prepare Docker stack and start...\n<<<<\n"
if [ ! -f "$_PROJECT_PATH/.env" ]; then
  cp $_PROJECT_PATH/default.env $_PROJECT_PATH/.env
fi
if [ ! -f "$_PROJECT_PATH/docker-compose.yml" ]; then
  if [ -f "$_PROJECT_PATH/samples/$_BASE.yml" ]; then
    cp $_PROJECT_PATH/samples/$_BASE.yml $_PROJECT_PATH/docker-compose.yml
  else
    # Default file is Apache/Mysql/Memcache/Solr/Mailhog.
    cp $_PROJECT_PATH/docker-compose.tpl.yml $_PROJECT_PATH/docker-compose.yml
  fi
fi
cd $_PROJECT_PATH
docker-compose build && docker-compose up -d

# Set-up composer.
if [ ! -f "/usr/bin/composer" ]; then
  echo -e "\n>>>>\n[setup::info] Set-up Composer and dependencies...\n<<<<\n"
  cd $HOME
  curl -sS https://getcomposer.org/installer | php -- --install-dir=$HOME --filename=composer
  sudo mv $HOME/composer /usr/bin/composer
  sudo chmod +x /usr/bin/composer
  /usr/bin/composer global require "hirak/prestissimo:^0.3" "drupal/coder"
else
  echo -e "\n>>>>\n[setup::notice] Composer already here!\n<<<<\n"
  # Install dependencies just in case.
  /usr/bin/composer global require "hirak/prestissimo:^0.3" "drupal/coder"
fi

# Set-up Code sniffer.
echo -e "\n>>>>\n[setup::info] Set-up Code sniffer and final steps...\n<<<<\n"
if [ -f "$HOME/.config/composer/vendor/bin/phpcs" ]; then
  $HOME/.config/composer/vendor/bin/phpcs --config-set installed_paths $HOME/.config/composer/vendor/drupal/coder/coder_sniffer
fi

# Check if containers are up...
RUNNING=$(docker inspect --format="{{ .State.Running }}" $_PHP 2> /dev/null)
if [ $? -eq 1 ]; then
  echo -e "\n>>>>\n[setup::ERROR] Container $_PHP does not exist...\n<<<<\n"
  # Wait a bit for stack to be up....
  sleep 30s
fi

# Add project variables to environment.
cat <<EOT >> $HOME/.profile
PATH=\$PATH:$HOME/.config/composer/vendor/bin
# Docker stack variables.
PROJECT_PATH="$_PROJECT_PATH"
PROJECT_ROOT="$_PROJECT_ROOT"
PROJECT_CONTAINER_NAME="$_PHP"
PROJECT_CONTAINER_ROOT="$_ROOT"
PROJECT_CONTAINER_WEB_ROOT="$_WEB"
DRUPAL_BIN="$_DRUPAL_CONSOLE"
DRUSH_BIN="$_DRUSH"
DRUSH_ROOT="--root=$_WEB"
DRUSH_CMD="$_DRUSH --root=$_WEB"
EOT

# Add docker and phpcs aliases.
cat <<EOT >> $HOME/.bash_aliases
# Docker
alias dk='docker'
# Docker-compose
alias dkc='docker-compose'
# Check Drupal coding standards
alias drcs="$HOME/.config/composer/vendor/bin/phpcs --standard=Drupal --extensions='php,module,inc,install,test,profile,theme,js,css,info,txt'"
# Check Drupal best practices
alias drcsbp="$HOME/.config/composer/vendor/bin/phpcs --standard=DrupalPractice --extensions='php,module,inc,install,test,profile,theme,js,css,info,txt,md'"
# Fix Drupal coding standards
alias drcsfix="$HOME/.config/composer/vendor/bin/phpcbf --standard=Drupal --extensions='php,module,inc,install,test,profile,theme,js,css,info,txt'"
EOT

# Add cmd in container bin for use with ssh.
sudo touch /usr/local/bin/dcmd
sudo chown $_USER:$_GROUP /usr/local/bin/dcmd
sudo chmod +x /usr/local/bin/dcmd
cat <<EOT > /usr/local/bin/dcmd
#!/bin/bash
docker exec -it --user apache $_PHP \$@
EOT

# Convenient links.
ln -s $_PROJECT_ROOT $HOME/www
sudo ln -s $_PROJECT_ROOT /www
sudo chown $_USER:$_GROUP /www
ln -s $_PROJECT_PATH $HOME/root

# Set up tools from stack.
if [ -d "$_PROJECT_PATH" ]; then
  echo -e "\n>>>>\n[setup::info] Setup Docker stack tools...\n<<<<\n"
  $_PROJECT_PATH/scripts/get-tools.sh install
fi

# Fix sock for privilleged, wait a bit for stack to be up....
sleep 30s
sudo chown $_USER:$_GROUP /var/run/docker.sock

echo -e "\n>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>\n
[setup::info] Docker compose stack install finished!\n
<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<\n"
