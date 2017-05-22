#!/bin/bash

# This is an helper to setup this docker compose Drupal stack on Ubuntu 16.04.
# This script must be run as ubuntu user with sudo privileges without password.
# We assume that docker and docker-compose is properly installed when using this
# script (From cloud config files in this folder).
# This script is used with a cloud config setup from this folder.

# Variables.
docker_stack_repo="https://github.com/Mogtofu33/docker-compose-drupal.git"
project_path="$HOME/docker-compose-drupal"
project_container_apache="ddd-apache"
project_root="$project_path/data/www"

# Fix permissions.
sudo chown -R ubuntu:ubuntu $HOME

# Get a Docker compose stack (Apache/Php/Mysql/Mailhog/Solr).
if [ ! -d "$project_path" ]; then
  echo "[setup::info] Clone Docker stack and tools..."
  git clone $docker_stack_repo $project_path
  # set up tools from stack
  cd $project_path;
  ./scripts/get-tools.sh
else
  echo "[setup::info] Docker stack already here!"
fi

# Set-up and launch this Docker compose stack.
echo "[setup::info] Prepare Docker stack and set-up tools..."
cp $project_path/default.env $project_path/.env
# Default file is Apache/Mysql/Memcache/Solr/Mailhog.
cp $project_path/docker-compose.tpl.yml $project_path/docker-compose.yml
cd $project_path
docker-compose up -d

# Set-up composer.
if [ ! -f "/usr/local/bin/composer" ]; then
  echo "[setup::info] Set-up Composer and dependencies..."
  cd $HOME
  curl -sS https://getcomposer.org/installer | php -- --install-dir=$HOME --filename=composer
  sudo mv $HOME/composer /usr/local/bin/composer
  sudo chmod +x /usr/local/bin/composer
  /usr/local/bin/composer global require "hirak/prestissimo:^0.3" "drupal/coder"
else
  echo "[setup::info] Composer already here!"
  # Install dependencies just in case.
  /usr/local/bin/composer global require "hirak/prestissimo:^0.3" "drupal/coder"
fi

# Set-up Code sniffer.
echo "[setup::info] Set-up Code sniffer and final steps..."
$HOME/.config/composer/vendor/bin/phpcs --config-set installed_paths $HOME/.config/composer/vendor/drupal/coder/coder_sniffer

# Check if containers are up...
RUNNING=$(docker inspect --format="{{ .State.Running }}" $project_container_apache 2> /dev/null)
if [ $? -eq 1 ]; then
  echo "[setup::ERROR] Container $project_container_apache does not exist..."
  # Wait a bit for stack to be up....
  sleep 30s
fi

# Add project variables to environment.
cat <<EOT >> $HOME/.profile
PATH=\$PATH:$HOME/.config/composer/vendor/bin
# Docker stack variables.
PROJECT_PATH="$project_path"
PROJECT_ROOT="$project_path/data/www"
PROJECT_CONTAINER_NAME="$project_container_apache"
EOT

# Add docker and phpcs aliases.
cat <<EOT >> $HOME/.bash_aliases
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

# Add cmd in container bin for use with ssh.
sudo touch /usr/local/bin/dcmd
sudo chown ubuntu:ubuntu /usr/local/bin/dcmd
sudo chmod +x /usr/local/bin/dcmd
cat <<EOT > /usr/local/bin/dcmd
#!/bin/bash
docker exec -it --user apache $project_container_apache \$@
EOT

# Convenient links.
ln -s $project_root $HOME/www
sudo ln -s $project_root /www
sudo chown ubuntu: /www
ln -s $project_path $HOME/root

echo -e ">>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>\n"
echo -e "[setup::info] Docker compose stack install finished!\n"
echo -e "<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<\n"
