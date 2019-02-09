#!/usr/bin/env bash
#
# Download and install Drupal 8 projects for DockerComposeDrupal.
#
# Usage:
#   install.sh list | install
#
# Depends on:
#  docker
#  DockerComposeDrupal
#
# Bash Boilerplate: https://github.com/alphabetum/bash-boilerplate
# Bash Boilerplate: Copyright (c) 2015 William Melody • hi@williammelody.com

if [[ -z ${STACK_ROOT} ]]
  then
  _SOURCE="${BASH_SOURCE[0]}"
  while [ -h "$_SOURCE" ]; do
    _DIR="$( cd -P "$( dirname "$_SOURCE" )" && pwd )"
    _SOURCE="$(readlink "$_SOURCE")"
    [[ $_SOURCE != /* ]] && _SOURCE="$_DIR/$_SOURCE"
  done
  _DIR="$( cd -P "$( dirname "$_SOURCE" )" && pwd )"

  if [[ ! -f $_DIR/helpers/common.sh ]]
  then
    echo -e "Missing helpers/common.sh file."
    exit 1
  fi
  source $_DIR/helpers/common.sh
fi

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
  _help_logo
  cat <<HEREDOC
Install and prepare multiple Drupal 8 project based on top Drupal distributions and some relevant ones:
 * https://www.drupal.org/project/project_distribution?f%5B2%5D=drupal_core%3A7234

Usage:
  ${_ME} list
  ${_ME} install -p drupal
  ${_ME} install -p drupal-demo -d postgres

Arguments: 
  list              List available projects.
  install | in      Download and setup a project.
  download | dl     Download a project codebase.
  setup | set       Install a project.
  delete            Delete a previously downloaded project.

Options with argument:
  -p --project      Optinal project name, from list option, if not set select prompt.
  -d --database     Database service: postgres or mysql, default "mysql"

Options:
  -f --force        Force prompt with Yes if any.
  -v --verbose      More messages, mostly with composer.
  -h --help         Show this screen.

HEREDOC
printf "\\n"
}

# Parse Options ###############################################################

# Initialize program option variables.
_PRINT_HELP=0

# Initialize additional expected option variables.
_CMD="print_help"
_SELECTED_PROJECT=0
_DEFAULT_DB="mysql"
__force=0
__verbose=""
__do_download=0
__do_setup=0

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
    -f|--force)
      __force=1
      ;;
    -v|--verbose)
      __verbose="-vvv"
      ;;
    -p|--project)
      _require_argument "${__option}" "${__maybe_param}"
      _SELECTED_PROJECT="${__maybe_param}"
      shift
      ;;
    -d|--database)
      _require_argument "${__option}" "${__maybe_param}"
      _DEFAULT_DB="${__maybe_param}"
      shift
      ;;
    --endopts)
      # Terminate option parsing.
      break
      ;;
    -*)
      _die printf "Unexpected option: %s\\n" "${__option}"
      ;;
    *)
      _CMD=${__option}
      ;;
  esac
  shift
done

###############################################################################
# Program Functions
###############################################################################

# _install()
#
# Description:
#   Download and setup the project.
_install() {
  __do_download=1
  __do_setup=1
  _install_dispatch
}
_in() {
  _install
}

# _download()
#
# Description:
#   Download the project.
_download() {
  __do_download=1
  __do_setup=0
  _install_dispatch
}
_dl() {
  _download
}

# _setup()
#
# Description:
#   Install a downloaded project.
_setup() {
  __do_download=0
  __do_setup=1
  _install_dispatch
}
_set() {
  _setup
}

# _install()
#
# Description:
#   Main install dispatcher.
_install_dispatch() {

  if [[ ${_SELECTED_PROJECT} == 0 ]]
  then
    _select_project
  fi

  # Select db early to avoid a middle script stop.
  if [[ ${__do_setup} == 1 ]]
  then
    _select_db
  fi

  __COUNT=${#DRUPAL_DISTRIBUTIONS[@]}

  for ((i=0; i<$__COUNT; i++))
  do

    __DID=${!DRUPAL_DISTRIBUTIONS[i]:0:1}
    __DESC=${!DRUPAL_DISTRIBUTIONS[i]:1:1}
    __INSTALL_PROFILE=${!DRUPAL_DISTRIBUTIONS[i]:2:1}
    __WEBROOT=${!DRUPAL_DISTRIBUTIONS[i]:3:1}
    __DOWNLOAD_TYPE=${!DRUPAL_DISTRIBUTIONS[i]:4:1}
    __PROJECT=${!DRUPAL_DISTRIBUTIONS[i]:5:1}
    __SETUP_TYPE=${!DRUPAL_DISTRIBUTIONS[i]:6:1}

    if [[ ${_SELECTED_PROJECT} == "${__DID}" ]]
    then
      if [[ $__do_download == 1 ]]
      then
        _download_dispatch "$__DOWNLOAD_TYPE"
      fi

      if [[ $__do_setup == 1 ]]
      then
        _setup_dispatch "$__SETUP_TYPE"
      fi
    fi
  done

  exit
}

# _ensure_download()
#
# Description:
#   Check if Drupal already here, stop stack if running.
_ensure_download() {
  if [[ -d ${STACK_DRUPAL_ROOT} ]]
  then
    if [[ -f ${STACK_DRUPAL_ROOT}/web/index.php ]] && [[ ${__force} == 0 ]]
    then
      printf "[Notice] Drupal already exist, do you want to continue and DELETE?\\n"
      _prompt_yn
    fi
    _stack_down
    ${SUDO} rm -rf "${STACK_DRUPAL_ROOT}"
  fi
}

# _download_dispatch()
#
# Description:
#   Download dispatcher depending download type of the project (composer or git).
_download_dispatch() {
  printf "[info] Start downloading %s\\n" "${__PROJECT}"
  __call="_download_${1}"
  $__call
  _fix_docroot
}

# _download_composer()
#
# Description:
#   Download with composer create-project command.
_download_composer() {
  # Setup Drupal 8 composer project.
  if [ -x "$(command -v composer)" ]; then
    _ensure_download
    composer create-project ${__PROJECT} ${STACK_DRUPAL_ROOT} --no-interaction --no-ansi --ignore-platform-reqs --remove-vcs --no-progress --prefer-dist ${__verbose}
    _stack_up
  else
    _ensure_download
    _stack_up
    _docker_exec_noi \
      composer create-project ${__PROJECT} /tmp/drupal --no-interaction --no-ansi --remove-vcs --no-progress --prefer-dist ${__verbose}
    _docker_exec_noi_u \
      chown apache:www-data ${WEB_ROOT}
    _docker_exec_noi \
      cp -Rp /tmp/drupal/. ${WEB_ROOT}
    _docker_exec_noi_u \
      rm -rf /tmp/drupal
  fi
}

# _download_composer_contenta()
#
# Description:
#   Download with specific contenta script.
_download_composer_contenta() {
  # Ensure we have a proper script.
  if [ -f "download-contenta.sh" ]; then
    rm -f "download-contenta.sh"
  fi
  if [ ${__verbose} == "" ]; then
    curl --silent --output download-contenta.sh "https://raw.githubusercontent.com/contentacms/contenta_jsonapi_project/8.x-2.x/scripts/download.sh"
  else
    curl --output download-contenta.sh "https://raw.githubusercontent.com/contentacms/contenta_jsonapi_project/8.x-2.x/scripts/download.sh"
  fi

  # Move to the container and set permission.
  $DOCKER cp download-contenta.sh ${PROJECT_CONTAINER_PHP}:/tmp/download-contenta.sh
  _docker_exec_noi_u \
    chmod a+x /tmp/download-contenta.sh

  # Contenta script require a new folder.
  _docker_exec_noi \
    sh -c 'exec '"/tmp/download-contenta.sh"' '"/tmp/contenta"''
  _docker_exec_noi \
    cp -Rp /tmp/contenta/. ${WEB_ROOT}

  # Cleanup.
  _docker_exec_noi \
    rm -Rf /tmp/contenta /tmp/download-contenta.sh
  rm -f "download-contenta.sh"
}

# _download_curl()
#
# Description:
#   Download with curl based on an url with a tar.gz archive.
_download_curl() {

  # Download the archive and extract.
  curl -fsSL "${__PROJECT}" -o /tmp/drupal.tar.gz
  tar -xzf /tmp/drupal.tar.gz -C /tmp/

  _ensure_download

  mv /tmp/drupal-composer-advanced-template-8.x-dev ${STACK_DRUPAL_ROOT}

  _stack_up

  _docker_exec_noi_u \
    chown -R ${LOCAL_UID}:${LOCAL_GID} ${WEB_ROOT}

  # Cleanup.
  rm -f /tmp/drupal.tar.gz

  # Setup Drupal 8 composer project.
  if [ -x "$(command -v composer)" ]; then
    composer install --working-dir="${STACK_DRUPAL_ROOT}" --no-suggest --no-interaction --ignore-platform-reqs ${__verbose}
    composer install-boostrap-sass --working-dir="${STACK_DRUPAL_ROOT}" ${__verbose}
  else
    _docker_exec_noi \
      composer install --working-dir="${WEB_ROOT}" --no-suggest --no-interaction ${__verbose}
    _docker_exec_noi \
      composer install-boostrap-sass --working-dir="${WEB_ROOT}" ${__verbose}
  fi

  if [ -x "$(command -v compass)" ]; then
    compass compile ${STACK_DRUPAL_ROOT}/web/themes/custom/bootstrap_sass
  else
    printf "[warning] Compile manually from your Drupal code root:\\ncompass compile web/themes/custom/bootstrap_sass\\n"
  fi
}

#
# Description:
#   Setup dispatcher depending Drupal profile name.
_setup_dispatch() {

  _stack_up

  printf "[info] Install %s with profile %s on db %s\\n" "${__DID}" "${__INSTALL_PROFILE}" "${DB_DRIVER}://${DB_USER}:${DB_PASSWORD}@${DB_HOST}/${DB_NAME}"

  _clean_setup

  _ensure_drush

  __call="_setup_${1}"
  $__call

  _fix_files_perm

  printf "\\n >> Access %s on\\nhttp://${PROJECT_BASE_URL}\\n >> Log-in with: admin / password\\n\\n" "${__DID}"
}

# _clean_setup()
#
# Description:
#   Helper to ensure we don't have an existing setup.
_clean_setup() {
  _docker_exec_noi \
    rm -f "${DRUPAL_DOCROOT}/sites/default/settings.php"
}

# _setup_standard()
#
# Description:
#   Setup with drush for a specific profile.
_setup_standard() {
  # Install this profile.
  _docker_exec_noi "${DRUSH_BIN}" -y site:install ${__INSTALL_PROFILE} \
    --root="${DRUPAL_DOCROOT}" \
    --account-pass="password" \
    --db-url="${DB_DRIVER}://${DB_USER}:${DB_PASSWORD}@${DB_HOST}/${DB_NAME}" \
    --site-name="My Drupal 8 ${__INSTALL_PROFILE} on DcD"
}

# _setup_varbase()
#
# Description:
#   Specific Varbase setup, can not be done with drush, but add drush for dev.
#   The problem is the Varbase install form with many options.
_setup_varbase() {
  printf "[warning] Varbase profile can not be installed from drush, install from \\nhttp://%s\\n" "${PROJECT_BASE_URL}"
}

# _setup_contenta()
#
# Description:
#   Specific Contenta setup, use .env and drush.
_setup_contenta() {
  # http://www.contentacms.org/#install
  if [ -f "${STACK_DRUPAL_ROOT}/.env" ]; then
    rm -f "${STACK_DRUPAL_ROOT}/.env"
  fi
  if [ -f "${STACK_DRUPAL_ROOT}/.env.local" ]; then
    rm -f "${STACK_DRUPAL_ROOT}/.env.local"
  fi

  cp "${STACK_DRUPAL_ROOT}/.env.example" "${STACK_DRUPAL_ROOT}/.env"
  cp "${STACK_DRUPAL_ROOT}/.env.local.example" "${STACK_DRUPAL_ROOT}/.env.local"

  echo "SITE_MAIL=admin@localhost" >> "${STACK_DRUPAL_ROOT}/.env"
  echo "ACCOUNT_MAIL=admin@localhost" >> "${STACK_DRUPAL_ROOT}/.env"
  echo "SITE_NAME='Contenta CMS'" >> "${STACK_DRUPAL_ROOT}/.env"
  echo "ACCOUNT_NAME=admin" >> "${STACK_DRUPAL_ROOT}/.env"
  echo "MYSQL_DATABASE=$DB_NAME" >> "${STACK_DRUPAL_ROOT}/.env"
  echo "MYSQL_HOSTNAME=$DB_HOST" >> "${STACK_DRUPAL_ROOT}/.env"
  echo "MYSQL_USER=$DB_USER" >> "${STACK_DRUPAL_ROOT}/.env"
  echo "MYSQL_PASSWORD=$DB_PASSWORD" >> "${STACK_DRUPAL_ROOT}/.env.local"
  echo "ACCOUNT_PASS=password" >> "${STACK_DRUPAL_ROOT}/.env.local"

  _docker_exec_noi \
    composer --working-dir="${WEB_ROOT}" run-script install:with-mysql ${__verbose}
}

# _setup_advanced()
#
# Description:
#   Specific install for advanced template with .env and drush.
_setup_advanced() {

  cp "${STACK_DRUPAL_ROOT}/.env.example" "${STACK_DRUPAL_ROOT}/.env"

  echo "MYSQL_DATABASE=$DB_NAME" >> "${STACK_DRUPAL_ROOT}/.env"
  echo "MYSQL_HOSTNAME=$DB_HOST" >> "${STACK_DRUPAL_ROOT}/.env"
  echo "MYSQL_USER=$DB_USER" >> "${STACK_DRUPAL_ROOT}/.env"
  echo "MYSQL_PASSWORD=$DB_PASSWORD" >> "${STACK_DRUPAL_ROOT}/.env"

  cp ${STACK_DRUPAL_ROOT}/example.settings.php ${STACK_DRUPAL_ROOT}/web/sites/default/settings.php
  cp ${STACK_DRUPAL_ROOT}/example.settings.local.php ${STACK_DRUPAL_ROOT}/web/sites/default/settings.local.php
  cp ${STACK_DRUPAL_ROOT}/example.settings.dev.php ${STACK_DRUPAL_ROOT}/web/sites/default/settings.dev.php
  cp ${STACK_DRUPAL_ROOT}/example.settings.prod.php ${STACK_DRUPAL_ROOT}/web/sites/default/settings.prod.php

  # Fix permission.
  _docker_exec_noi_u \
    chown -R ${LOCAL_UID}:${LOCAL_GID} ${DRUPAL_DOCROOT}/sites/default/

  # Install this profile with config_installer
  _docker_exec_noi "${DRUSH_BIN}" -y site:install "${__INSTALL_PROFILE}" \
    config_installer_sync_configure_form.sync_directory="../config/sync" \
    --root="${DRUPAL_DOCROOT}" \
    --account-pass="password" \
    --db-url="${DB_DRIVER}://${DB_USER}:${DB_PASSWORD}@${DB_HOST}/${DB_NAME}"
}

_ensure_drush() {
  if ! [ -f "${STACK_DRUPAL_ROOT}/vendor/drush/drush/drush" ]; then
    printf "[info] Install missing drush\\n"
    # Drush is not included in varbase distribution.
    if [ -x "$(command -v composer)" ]; then
      composer require drush/drush --working-dir="${STACK_DRUPAL_ROOT}" --ignore-platform-reqs ${__verbose}
    else
      _docker_exec_noi \
        composer require drush/drush --working-dir="${WEB_ROOT}" ${__verbose}
    fi
  fi
}

# _select_project()
#
# Description:
#   Helper to let user select a project for this script.
_select_project() {

  printf "For more information on each option run %s list\\n" "${_ME}"

  __list=()
  __COUNT=${#DRUPAL_DISTRIBUTIONS[@]}
  for ((i=0; i<$__COUNT; i++))
  do
    __list[i]=${!DRUPAL_DISTRIBUTIONS[i]:0:1}
  done

  select opt in "Cancel" "${__list[@]}"; do
    case $opt in
      *)
        _SELECTED_PROJECT=$opt
        break
        ;;
    esac
  done

  if [[ ${_SELECTED_PROJECT} == "" ]]
  then
    die "Not a valid option."
  fi
}

# _select_db()
#
# Description:
#   Helper to let user select a database container for this script.
_select_db() {

  _DB=0
  _DB_LIST=0

  # Check if any mysql container is running.
  RUNNING=$(docker ps -f "name=mariadb" -f "status=running" -q | head -1 2> /dev/null)
  if [[ -n "$RUNNING" ]]
  then
    _DB_LIST[0]="mariadb"
  fi

  # Check if any mysql container is running.
  RUNNING=$(docker ps -f "name=mysql" -f "status=running" -q | head -1 2> /dev/null)
  if [[ -n "$RUNNING" ]]
  then
    _DB_LIST[0]="mysql"
  fi

  # Check if any postgresql container is running.
  RUNNING=$(docker ps -f "name=pgsql" -f "status=running" -q | head -1 2> /dev/null)
  if [[ -n "$RUNNING" ]]
  then
    _DB_LIST[1]="postgres"
  fi

  if [[ ${_DB_LIST} == 0 ]]
  then
    die "No database container found, please ensure your stack is running eg: docker-compose up -d."
  fi

  if [[ ${_DB_LIST[0]} == "$_DEFAULT_DB" ]] || [[ ${_DB_LIST[1]} == "$_DEFAULT_DB" ]]
  then
    _DB=$_DEFAULT_DB
  fi

  if [[ ${#_DB_LIST[@]} > 1 ]] && [[ $_DB == 0 ]]
  then
    printf "Select a database container:\\n"
    select opt in "${_DB_LIST[@]}"; do
      case $opt in
        *)
          _DB=$opt
          break
          ;;
      esac
    done
  else
    printf "[info] Found database %s\\n" ${_DB}
  fi

  if [[ $_DB == "postgres" ]]
  then
    DB_DRIVER=pgsql
    DB_HOST=pgsql
  fi
}

# _list()
#
# Description:
#   Helper to return the list of available distributions/profiles for this
#   script with description.
_list() {
  printf "Available distributions:\\n"
  __COUNT=${#DRUPAL_DISTRIBUTIONS[@]}
  for ((i=0; i<$__COUNT; i++))
  do
    __DID=${!DRUPAL_DISTRIBUTIONS[i]:0:1}
    __DESC=${!DRUPAL_DISTRIBUTIONS[i]:1:1}
    printf "  %s\\n   * %s\\n" "${__DID}" "${__DESC}"
  done
}

# _fix_docroot()
#
# Description:
#   Helper to fix Drupal web root, some projects use docroot, other web...
_fix_docroot() {
  if [[ ${__WEBROOT} != "web" ]]
  then
    printf "[info] Fix Drupal %s to web\\n" ${__WEBROOT}
    _docker_exec_noi \
      ln -s ${WEB_ROOT}/${__WEBROOT} ${DRUPAL_DOCROOT}
  fi
}

# _fix_files_perm()
#
# Description:
#   Helper to fix Drupal permission hardly.
_fix_files_perm() {
  _docker_exec_noi_u \
    mkdir -p ${DRUPAL_DOCROOT}/sites/default/files/tmp
  _docker_exec_noi_u \
    mkdir -p ${DRUPAL_DOCROOT}/sites/default/files/private
  _docker_exec_noi_u \
    chmod -R 777 ${DRUPAL_DOCROOT}/sites/default/files
  _docker_exec_noi_u \
    chown -R ${LOCAL_UID}:${LOCAL_GID} ${DRUPAL_DOCROOT}/sites/default/files
  # contenta specific.
  if [[ ${__DID} == "contenta" ]]
  then
    _docker_exec_noi_u \
      chmod -R 660 ${WEB_ROOT}/keys/public.key
  fi
  _docker_exec_noi_u \
    chmod -R 777 /tmp
}

# _delete()
#
# Description:
#   Delete a previous downloaded Drupal.
_delete() {
  if [ ${__force} == 0 ]; then
    _prompt_yn
  fi
  _stack_down
  ${SUDO} rm -rf "${STACK_DRUPAL_ROOT}"
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

    if ! [ -x "$(command -v sudo)" ]; then
      SUDO=""
    else
      SUDO="sudo"
    fi

    # Run command if exist.
    __call="_${_CMD}"
    if [ "$(type -t "${__call}")" == 'function' ]; then
      $__call
    else
      printf "[ERROR] Unknown command: %s\\n" "${_CMD}"
    fi

  fi

}

# Call `_main` after everything has been defined.
_main
