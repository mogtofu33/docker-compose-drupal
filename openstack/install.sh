#!/bin/bash

# This is an helper to setup this docker compose Drupal stack on Ubuntu 16.04/18.04.
# This script must be run as ubuntu user with sudo privileges without password.
# We assume that docker and docker-compose is properly installed when using this
# script (From cloud config files in this folder).
# This script is used with a cloud config setup from this folder.

set -o nounset
set -o errexit
trap 'echo "Aborting due to errexit on line $LINENO. Exit code: $?" >&2' ERR
set -o errtrace
set -o pipefail
IFS=$'\n\t'

###############################################################################
# Help
###############################################################################

# _print_help()
#
# Usage:
#   _print_help
#
# Print the program help information.
_print_help() {
  cat <<HEREDOC
Install Docker Compose Drupal on a Ubuntu distribution, firstly in Openstack.

Options:
 --down                Set the stack down at the end of setup
  -h --help            Show this screen.

Options with argument:
 -s|--stack            Name of stack file to use from ./samples folder,
                       default is the full stack.
 -i|--install          Install a Drupal profile from
                       ./scripts/install-drupal.sh, eg: drupal, drupal-min...
 -b|--branch           Branch for this project, default is "master"
 -u|--user             Local user name to use, default "ubuntu"
 -g|--group            Local user group to use, default "ubuntu"
 -p|--path             Local project path, default "$HOME/docker-compose-drupal"

Usage:
  ./install.sh -b apache_mysql_php -i drupal-min
  ./install.sh -b apache_postgres9_php --down

HEREDOC
printf "\\n"
}

# Parse Options ###############################################################

# Initialize program option variables.
_PRINT_HELP=0

# Initialize additional expected option variables.
__LOCAL_USER="ubuntu"
__LOCAL_GROUP="ubuntu"
__PROJECT_PATH="${HOME}/docker-compose-drupal"
__BASE_STACK="full"
__PUT_DOWN=0
__INSTALL_DRUPAL=0
__BRANCH="master"

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
    -h|--help)
      _PRINT_HELP=1
      ;;
    --down)
      __PUT_DOWN=1
      ;;
    -s|--stack)
      _require_argument "${__option}" "${__maybe_param}"
      __BASE_STACK="${__maybe_param}"
      shift
      ;;
    -i|--install)
      _require_argument "${__option}" "${__maybe_param}"
      __INSTALL_DRUPAL="${__maybe_param}"
      shift
      ;;
    -b|--branch)
      _require_argument "${__option}" "${__maybe_param}"
      __BRANCH="${__maybe_param}"
      shift
      ;;
    -u|--user)
      _require_argument "${__option}" "${__maybe_param}"
      __LOCAL_USER="${__maybe_param}"
      shift
      ;;
    -g|--group)
      _require_argument "${__option}" "${__maybe_param}"
      __LOCAL_GROUP="${__maybe_param}"
      shift
      ;;
    -p|--path)
      _require_argument "${__option}" "${__maybe_param}"
      __PROJECT_PATH="${__maybe_param}"
      shift
      ;;
    --endopts)
      # Terminate option parsing.
      break
      ;;
    -*)
      printf "[setup::WARNING] Unexpected option: %s\\n" "${__option}"
      ;;
  esac
  shift
done

###############################################################################
# Program Functions
###############################################################################

_ensure_permissions() {
  printf "\\n[setup::info] Ensure permissions.\\n\\n"
  sudo chown -R ${__LOCAL_USER}:${__LOCAL_GROUP} ${HOME}
}

_ensure_docker() {
  printf "\\n[setup::info] Ensure Docker user fix.\\n\\n"
  # Set Docker group to our user (temporary fix?).
  sudo usermod -a -G docker ${__LOCAL_USER}
}

_install_stack() {
  # Get a Docker compose stack.
  if ! [ -d "${__PROJECT_PATH}" ]; then
    printf "\\n[setup::info] Get Docker stack %s\\n\\n" "${__BRANCH}"
    git clone -b ${__BRANCH} https://gitlab.com/mog33/docker-compose-drupal.git ${__PROJECT_PATH}
    if ! [ -f "${__PROJECT_PATH}/docker-compose.tpl.yml" ]; then
      printf "\\n[setup::ERROR] Failed to download Docker compose Drupal :(\\n\\n"
      exit 1
    fi
  else
    printf "\\n\\n[setup::notice] Docker stack already here!\\n\\n"
    exit 1
  fi

  # Set-up and launch this Docker compose stack.
  printf "\\n\\n[setup::info] Prepare Docker stack...\\n\\n"
  (cd ${__PROJECT_PATH} && make setup)

}

_source_common() {
  # Get stack variables and functions.
  if ! [ -f ${__PROJECT_PATH}/scripts/helpers/common.sh ]; then
    printf "\\n\\n[setup::ERROR] Missing %s file!\\n\\n" "${__PROJECT_PATH}/scripts/helpers/common.sh"
    exit 1
  fi
  source ${__PROJECT_PATH}/scripts/helpers/common.sh
}

_setup_stack() {
  printf "\\n\\n[setup::info] Prepare stack %s\\n\\n" "${__BASE_STACK}"
  if [ -f "${STACK_ROOT}/samples/${__BASE_STACK}.yml" ]; then
    cp ${STACK_ROOT}/samples/${__BASE_STACK}.yml ${STACK_ROOT}/docker-compose.yml
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
    composer selfupdate
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
  printf "\\n\\n[setup::info] Download Drupal %s\\n\\n" "${__INSTALL_DRUPAL}"
  ${STACK_ROOT}/scripts/install-drupal.sh download -f -p ${__INSTALL_DRUPAL}
}

_setup_drupal() {
  printf "\\n\\n[setup::info] Install Drupal ${__INSTALL_DRUPAL}\\n\\n"
  # Wait a bit for the stack to be up.
  sleep 20s
  ${STACK_ROOT}/scripts/install-drupal.sh setup -f -p ${__INSTALL_DRUPAL}
}

_up_stack() {
  printf "\\n\\n[setup::info] Up stack...\\n\\n"
  $_DOCKER_COMPOSE --file "${STACK_ROOT}/docker-compose.yml" up -d --build
}

_down_stack() {
  printf "\\n\\n[setup::info] Down stack...\\n\\n"
  sleep 20s
  $_DOCKER_COMPOSE --file "${STACK_ROOT}/docker-compose.yml" down
}

_env_tasks() {
  printf "\\n\\n[setup::info] Set env...\\n\\n"
  # Add composer path to environment.
  cat <<EOT >> ${HOME}/.profile
PATH=\$PATH:${HOME}/.config/composer/vendor/bin
EOT

  # Add docker, phpcs aliases.
  cat <<EOT >> ${HOME}/.bash_aliases
# Docker
alias dk='docker'
# Docker-compose
alias dkc='docker-compose'
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
  # Drush and Drupal links.
  if ! [ -f "/usr/local/bin/drush" ] && ! [ -f "/usr/local/bin/drush" ]; then
    sudo ln -s ${STACK_ROOT}/scripts/drush /usr/local/bin/drush
    sudo chmod a+x /usr/local/bin/drush
  fi
  if ! [ -f "/usr/local/bin/drupal" ] && ! [ -f "/usr/local/bin/drupal" ]; then
    sudo ln -s ${STACK_ROOT}/scripts/drupal /usr/local/bin/drupal
    sudo chmod a+x /usr/local/bin/drupal
  fi
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

_install_all() {
  _ensure_permissions
  _ensure_docker
  _install_stack
  _source_common
  _setup_stack
  _install_composer

  if ! [ ${__INSTALL_DRUPAL} == 0 ]; then
    _download_drupal
  fi

  _up_stack

  if ! [ ${__INSTALL_DRUPAL} == 0 ]; then
    _setup_drupal
  fi

  _env_tasks
  _links
  _get_tools
  _ensure_permissions

  if ((__PUT_DOWN))
  then
    _down_stack
  fi

  printf "\\n\\n>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>
  \\n[setup::info] Docker compose stack install finished!\\n
<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<\\n\\n"
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

  if ((_PRINT_HELP))
  then
    _print_help
  else
    _install_all
  fi

}

# Call `_main` after everything has been defined.
_main "$@"
