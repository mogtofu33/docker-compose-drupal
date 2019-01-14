#!/bin/bash

# This is an helper to setup this docker compose Drupal stack on Ubuntu 16.04/18.04.
# This script must be run as ubuntu user with sudo privileges without password.
# We assume that docker and docker-compose is properly installed when using this
# script (From cloud config files in this folder).
# This script is used with a cloud config setup from this folder.

# Help usage
# Options:
#  --down                Set the stack down at the end of setup
# Options with values:
#  -s|--stack            Name of stack file to use from ./samples folder,
#                        default is the full stack.
#  -i|--install          Install a Drupal profile from
#                        ./scripts/install-drupal.sh, eg: drupal, drupal-min...
#  -b|--branch           Branch for this project, default is "master"
#  -u|--user             Local user name to use, default "ubuntu"
#  -g|--group            Local user group to use, default "ubuntu"
#  -p|--path             Local project path, default "$HOME/docker-compose-drupal"

# Usage:
#   ./install.sh -b apache_mysql_php -i drupal-min
#   ./install.sh -b apache_postgres9_php --down

set -o nounset
set -o errexit
trap 'echo "Aborting due to errexit on line $LINENO. Exit code: $?" >&2' ERR
set -o errtrace
set -o pipefail
SAFER_IFS=$'\n\t'
IFS="${SAFER_IFS}"

# Parse Options ###############################################################

# Initialize program option variables.
__local_user="ubuntu"
__local_group="ubuntu"
__project_path="${HOME}/docker-compose-drupal"
__base_stack="full"
__set_down=0
__install_drupal=0
__branch="master"

# _require_argument()
#
# Usage:
#   _require_argument <option> <argument>
#
# If <argument> is blank or another option, print an error message and  exit
# with status 1.
_require_argument() {
  # Set local variables from arguments.
  #
  # NOTE: 'local' is a non-POSIX bash feature and keeps the variable local to
  # the block of code, as defined by curly braces. It's easiest to just think
  # of them as local to a function.
  local _option="${1:-}"
  local _argument="${2:-}"

  if [[ -z "${_argument}" ]] || [[ "${_argument}" =~ ^- ]]
  then
    _die printf "Option requires a argument: %s\\n" "${_option}"
  fi
}

while [[ ${#} -gt 0 ]]
do
  __option="${1:-}"
  __maybe_param="${2:-}"
  case "${__option}" in
    --down)
      __set_down=1
      ;;
    -s|--stack)
      _require_argument "${__option}" "${__maybe_param}"
      __base_stack="${__maybe_param}"
      shift
      ;;
    -i|--install)
      _require_argument "${__option}" "${__maybe_param}"
      __install_drupal="${__maybe_param}"
      shift
      ;;
    -b|--branch)
      _require_argument "${__option}" "${__maybe_param}"
      __branch="${__maybe_param}"
      shift
      ;;
    -u|--user)
      _require_argument "${__option}" "${__maybe_param}"
      __local_user="${__maybe_param}"
      shift
      ;;
    -g|--group)
      _require_argument "${__option}" "${__maybe_param}"
      __local_group="${__maybe_param}"
      shift
      ;;
    -p|--path)
      _require_argument "${__option}" "${__maybe_param}"
      __project_path="${__maybe_param}"
      shift
      ;;
    --endopts)
      # Terminate option parsing.
      break
      ;;
    -*)
      _die printf "Unexpected option: %s\\n" "${__option}"
      ;;
  esac
  shift
done

###############################################################################
# Program Functions
###############################################################################

_ensure_permissions() {
  printf "\\n[setup::info] Ensure permissions.\\n\\n"
  sudo chown -R ${__local_user}:${__local_group} ${HOME}
}

_ensure_docker() {
  printf "\\n[setup::info] Ensure Docker user fix.\\n\\n"
  # Set Docker group to our user (temporary fix?).
  sudo usermod -a -G docker ${__local_user}
}

_install_stack() {
  # Get a Docker compose stack.
  if ! [ -d "${__project_path}" ]; then
    printf "\\n[setup::info] Get Docker stack %s\\n\\n" "${__branch}"
    git clone -b ${__branch} https://gitlab.com/mog33/docker-compose-drupal.git ${__project_path}
    if ! [ -f "${__project_path}/docker-compose.tpl.yml" ]; then
      printf "\\n[setup::ERROR] Failed to download Docker compose Drupal :(\\n\\n"
      exit 1
    fi
  else
    printf "\\n\\n[setup::notice] Docker stack already here!\\n\\n"
    exit 1
  fi

  # Set-up and launch this Docker compose stack.
  printf "\\n\\n[setup::info] Prepare Docker stack...\\n\\n"
  (cd ${__project_path} && make setup)

}

_source_common() {
  # Get stack variables and functions.
  if ! [ -f ${__project_path}/scripts/helpers/common.sh ]; then
    printf "\\n\\n[setup::ERROR] Missing %s file!\\n\\n" "${__project_path}/scripts/helpers/common.sh"
    exit 1
  fi
  source ${__project_path}/scripts/helpers/common.sh
}

_setup_stack() {
  printf "\\n\\n[setup::info] Prepare stack %s\\n\\n" "${__base_stack}"
  if [ -f "${STACK_ROOT}/samples/${__base_stack}.yml" ]; then
    cp ${STACK_ROOT}/samples/${__base_stack}.yml ${STACK_ROOT}/docker-compose.yml
  fi
}

_install_composer() {
  # Set-up Composer.
  if ! [ -x "$(command -v composer)" ]; then
    printf "\\n\\n[setup::info] Set-up Composer and dependencies...\\n\\n"
    cd ${HOME}
    curl -sS https://getcomposer.org/installer | php -- --install-dir=${HOME} --filename=composer
    sudo mv ${HOME}/composer /usr/local/bin/composer
    sudo chmod +x /usr/local/bin/composer
    composer global require "hirak/prestissimo:^0.3" "drupal/coder"
  else
    printf "\\n\\n[setup::notice] Composer already here!\\n\\n"
    if ! [ -d "${HOME}/.config/composer/vendor/hirak" ]; then
      composer global require "hirak/prestissimo:^0.3" "drupal/coder"
    fi
  fi

  # Set-up Code sniffer.
  if [ -f "${HOME}/.config/composer/vendor/bin/phpcs" ]; then
    printf "\\n\\n[setup::info] Set-up Code sniffer...\\n\\n"
    ${HOME}/.config/composer/vendor/bin/phpcs --config-set installed_paths ${HOME}/.config/composer/vendor/drupal/coder/coder_sniffer
  fi
}

_download_drupal() {
  printf "\\n\\n[setup::info] Download Drupal %s\\n\\n" "${__install_drupal}"
  ${STACK_ROOT}/scripts/install-drupal.sh download ${__install_drupal}
}

_setup_drupal() {
  printf "\\n\\n[setup::info] Install Drupal ${__install_drupal}\\n\\n"
  # Wait a bit for the stack to be up.
  sleep 20s
  ${STACK_ROOT}/scripts/install-drupal.sh setup ${__install_drupal}
}

_up_stack() {
  printf "\\n\\n[setup::info] Up stack...\\n\\n"
  docker-compose --file "${STACK_ROOT}/docker-compose.yml" up -d --build
}

_down_stack() {
  printf "\\n\\n[setup::info] Down stack...\\n\\n"
  sleep 20s
  docker-compose --file "${STACK_ROOT}/docker-compose.yml" down
}

_env_tasks() {
  printf "\\n\\n[setup::info] Set env...\\n\\n"
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
}

_links() {
  printf "\\n\\n[setup::info] Set links...\\n\\n"
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
}

_get_tools() {
  # Set up tools from stack.
  if [ -f "${STACK_ROOT}/scripts/get-tools.sh" ]; then
    printf "\\n\\n[setup::info] Setup Docker stack tools...\\n\\n"
    ${STACK_ROOT}/scripts/get-tools.sh install
  fi
}

###############################################################################
# Main
###############################################################################

# _main()
#
# Usage:
#   _main [<options>] [<arguments>]
#
# Description:
#   Entry point for the program, handling basic option parsing and dispatching.
_main() {
  _ensure_permissions
  _ensure_docker
  _install_stack
  _source_common
  _setup_stack
  _install_composer
  if ! [ ${__install_drupal} == 0 ]; then
    _download_drupal
  fi
  _up_stack
  if ! [ ${__install_drupal} == 0 ]; then
    _setup_drupal
  fi
  _env_tasks
  _links
  _get_tools
  _ensure_permissions
  if [ ${__set_down} == 1 ]; then
    _down_stack
  fi
  printf "\\n\\n>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>
  \\n[setup::info] Docker compose stack install finished!\\n
<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<\\n\\n"
}

# Call `_main` after everything has been defined.
_main "$@"
