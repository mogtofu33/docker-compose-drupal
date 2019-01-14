#!/bin/bash

# This is an helper to setup this docker compose Drupal stack on Ubuntu 16.04/18.04.
# This script must be run as ubuntu user with sudo privileges without password.
# We assume that docker and docker-compose is properly installed when using this
# script (From cloud config files in this folder).
# This script is used with a cloud config setup from this folder.

# Accept arguments in order:
# 1 - Stack name from ./samples folder, or any string for default
# 2 - Drupal install profile from scripts/install-drupal.sh, eg drupal,
#     drupal-min, drupal-demo...
# 3 - This project specific branch, default is "master"
#
# ./install.sh apache_mysql_php_memcache_solr drupal-min

# Project variables from arguments.
__base_stack=${1-"none"}
__install_drupal=${2-"0"}
__branch=${3-"master"}

# Project variables.
__local_user="ubuntu"
__local_group="ubuntu"
__project_path="${HOME}/docker-compose-drupal"

# Ensure permissions.
sudo chown -R ${__local_user}:${__local_group} ${HOME}

# Set Docker group to our user (temporary fix?).
sudo usermod -a -G docker ${__local_user}

# Get a Docker compose stack.
if ! [ -d "${__project_path}" ]; then
  echo -e "\n>>>>\n[setup::info] Get Docker stack ${__branch}...\n<<<<\n"
  git clone -b ${__branch} https://gitlab.com/mog33/docker-compose-drupal.git ${__project_path}
  if ! [ -f "${__project_path}/docker-compose.tpl.yml" ]; then
    echo -e "\n>>>>\n[setup::error] Failed to download DockerComposeDrupal :(\n<<<<\n"
    exit 1
  fi
else
  echo -e "\n>>>>\n[setup::notice] Docker stack already here!\n<<<<\n"
  exit 1
fi

# Set-up and launch this Docker compose stack.
echo -e "\n>>>>\n[setup::info] Prepare Docker stack...\n<<<<\n"
(cd ${__project_path} && make setup)

# Get stack variables and functions.
if ! [ -f ${__project_path}/scripts/helpers/common.sh ]; then
  echo -e "\n>>>>\n[setup::error] Missing ${__project_path}/scripts/helpers/common.sh file!"
  exit 1
fi
source ${__project_path}/scripts/helpers/common.sh

echo -e "\n>>>>\n[setup::info] Prepare stack ${__base_stack}\n<<<<\n"
if [ -f "${STACK_ROOT}/samples/${__base_stack}.yml" ]; then
  cp ${STACK_ROOT}/samples/${__base_stack}.yml ${STACK_ROOT}/docker-compose.yml
fi

# Set-up Composer.
if ! [ -x "$(command -v composer)" ]; then
  echo -e "\n>>>>\n[setup::info] Set-up Composer and dependencies...\n<<<<\n"
  cd ${HOME}
  curl -sS https://getcomposer.org/installer | php -- --install-dir=${HOME} --filename=composer
  sudo mv ${HOME}/composer /usr/local/bin/composer
  sudo chmod +x /usr/local/bin/composer
  composer global require "hirak/prestissimo:^0.3" "drupal/coder"
else
  echo -e "\n>>>>\n[setup::notice] Composer already here!\n<<<<\n"
  if ! [ -d "${HOME}/.config/composer/vendor/hirak" ]; then
    composer global require "hirak/prestissimo:^0.3" "drupal/coder"
  fi
fi

# Set-up Code sniffer.
if [ -f "${HOME}/.config/composer/vendor/bin/phpcs" ]; then
  echo -e "\n>>>>\n[setup::info] Set-up Code sniffer...\n<<<<\n"
  ${HOME}/.config/composer/vendor/bin/phpcs --config-set installed_paths ${HOME}/.config/composer/vendor/drupal/coder/coder_sniffer
fi

if ! [ ${__install_drupal} == "0" ]; then
  echo -e "\n>>>>\n[setup::info] Download Drupal ${__install_drupal}\n<<<<\n"
  ${STACK_ROOT}/scripts/install-drupal.sh download ${__install_drupal}
fi

docker-compose --file "${STACK_ROOT}/docker-compose.yml" up -d --build

if ! [ ${__install_drupal} == "0" ]; then
  echo -e "\n>>>>\n[setup::info] Install Drupal ${__install_drupal}\n<<<<\n"
  # Wait a bit for the stack to be up.
  sleep 20s
  ${STACK_ROOT}/scripts/install-drupal.sh setup ${__install_drupal}
fi

# Add composer path to environment.
cat <<EOT >> ${HOME}/.profile
PATH=\$PATH:${HOME}/.config/composer/vendor/bin
EOT

# Add docker, phpcs, drush and drupal console aliases.
cat <<EOT >> ${HOME}/.bash_aliases
# Dockercd do 
alias dk='docker'
# Docker-compose
alias dkc='docker-compose'
# Drush and Drupal console
alias drush="${STACK_ROOT}/scripts/drush"
alias drupal="${STACK_ROOT}/scripts/drupal"
# Check Drupal coding standards
alias csdr="${HOME}/.config/composer/vendor/bin/phpcs --standard=Drupal --extensions='php,module,inc,install,test,profile,theme,info'"
# Check Drupal best practices
alias csbpdr="${HOME}/.config/composer/vendor/bin/phpcs --standard=DrupalPractice --extensions='php,module,inc,install,test,profile,theme,info'"
# Fix Drupal coding standards
alias csfixdr="${HOME}/.config/composer/vendor/bin/phpcbf --standard=Drupal --extensions='php,module,inc,install,test,profile,theme,info'"
EOT

# Convenient links.
if ! [ -d "${HOME}/drupal" ]; then
  ln -s ${STACK_DRUPAL_ROOT} ${HOME}/drupal
fi
if ! [ -d "${HOME}/dump" ]; then
  ln -s ${STACK_ROOT}/${HOST_DATABASE_DUMP#'./'} ${HOME}/dump
fi
if ! [ -d "${HOME}/scripts" ]; then
  ln -s ${STACK_ROOT}/scripts ${HOME}/scripts
fi

# Set up tools from stack.
if [ -d "${STACK_ROOT}" ]; then
  echo -e "\n>>>>\n[setup::info] Setup Docker stack tools...\n<<<<\n"
  ${STACK_ROOT}/scripts/get-tools.sh install
fi

# Ensure permissions.
sudo chown -R ${__local_user}:${__local_group} ${HOME}

echo -e "\n>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>\n
[setup::info] Docker compose stack install finished!\n
<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<\n"
