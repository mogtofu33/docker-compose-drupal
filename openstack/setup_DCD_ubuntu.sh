#!/bin/bash

# This is an helper to setup this docker compose Drupal stack on Ubuntu 16.04/18.04.
# This script must be run as ubuntu user with sudo privileges without password.
# We assume that docker and docker-compose is properly installed when using this
# script (From cloud config files in this folder).
# This script is used with a cloud config setup from this folder.

# Variables.
docker_stack_repo="https://github.com/Mogtofu33/docker-compose-drupal.git"
docker_stack_branch=${1-"master"}
docker_stack_base=${2-"all"}
project_path="$HOME/docker-compose-drupal"
project_container_php="dcd-php"
project_root="$project_path/data/www"
project_container_root="/var/www/localhost/drupal"
project_container_web_root="$project_container_root/web"
drupal_bin="$project_container_root/vendor/bin/drupal"
drush_bin="$project_container_root/vendor/bin/drush"
drush_root="--root=$project_container_web_root"

# Fix permissions.
sudo chown -R ubuntu:ubuntu $HOME

# Set Docker group to ubuntu user.
sudo usermod -a -G docker ubuntu

# Get a Docker compose stack (Apache/Php/Mysql/Mailhog/Solr).
if [ ! -d "$project_path" ]; then
  echo -e "\n>>>>\n[setup::info] Clone Docker stack...\n<<<<\n"
  git clone -b $docker_stack_branch $docker_stack_repo $project_path
else
  echo -e "\n>>>>\n[setup::notice] Docker stack already here!\n<<<<\n"
fi

# Set-up and launch this Docker compose stack.
echo -e "\n>>>>\n[setup::info] Prepare Docker stack and start...\n<<<<\n"
if [ ! -f "$project_path/.env" ]; then
  cp $project_path/default.env $project_path/.env
fi
if [ ! -f "$project_path/docker-compose.yml" ]; then
  if [ -f "$project_path/samples/$docker_stack_base.yml" ]; then
    cp $project_path/samples/$docker_stack_base.yml $project_path/docker-compose.yml
  else
    # Default file is Apache/Mysql/Memcache/Solr/Mailhog.
    cp $project_path/docker-compose.tpl.yml $project_path/docker-compose.yml
  fi
fi
cd $project_path
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
RUNNING=$(docker inspect --format="{{ .State.Running }}" $project_container_php 2> /dev/null)
if [ $? -eq 1 ]; then
  echo -e "\n>>>>\n[setup::ERROR] Container $project_container_php does not exist...\n<<<<\n"
  # Wait a bit for stack to be up....
  sleep 30s
fi

# Add project variables to environment.
cat <<EOT >> $HOME/.profile
PATH=\$PATH:$HOME/.config/composer/vendor/bin
# Docker stack variables.
PROJECT_PATH="$project_path"
PROJECT_ROOT="$project_root"
PROJECT_CONTAINER_NAME="$project_container_php"
PROJECT_CONTAINER_ROOT="$project_container_root"
PROJECT_CONTAINER_WEB_ROOT="$project_container_web_root"
DRUPAL_BIN="$drupal_bin"
DRUSH_BIN="$drush_bin"
DRUSH_ROOT="--root=$project_container_web_root"
DRUSH_CMD="$drush_bin --root=$project_container_web_root"
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
sudo chown ubuntu:ubuntu /usr/local/bin/dcmd
sudo chmod +x /usr/local/bin/dcmd
cat <<EOT > /usr/local/bin/dcmd
#!/bin/bash
docker exec -it --user apache $project_container_php \$@
EOT

# Convenient links.
ln -s $project_root $HOME/www
sudo ln -s $project_root /www
sudo chown ubuntu: /www
ln -s $project_path $HOME/root

# Set up tools from stack.
if [ -d "$project_path" ]; then
  echo -e "\n>>>>\n[setup::info] Setup Docker stack tools...\n<<<<\n"
  cd $project_path;
  scripts/get-tools.sh install
fi

# Fix sock for privilleged, wait a bit for stack to be up....
sleep 30s
sudo chown 1000:1000 /var/run/docker.sock

echo -e "\n>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>\n
[setup::info] Docker compose stack install finished!\n
<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<\n"
