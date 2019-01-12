#!/usr/bin/env bash
#
# Download and install Drupal 8 projects for docker4drupal or dockerComposeDrupal.
#
# Usage:
#   install.sh list | install
#
# Depends on:
#  docker
#  docker4drupal or dockerComposeDrupal
#
# Bash Boilerplate: https://github.com/alphabetum/bash-boilerplate
# Bash Boilerplate: Copyright (c) 2015 William Melody • hi@williammelody.com

_SOURCE="${BASH_SOURCE[0]}"
while [ -h "$_SOURCE" ]; do # resolve $_SOURCE until the file is no longer a symlink
  _DIR="$( cd -P "$( dirname "$_SOURCE" )" && pwd )"
  _SOURCE="$(readlink "$_SOURCE")"
  [[ $_SOURCE != /* ]] && _SOURCE="$_DIR/$_SOURCE" # if $_SOURCE was a relative symlink, we need to resolve it relative to the path where the symlink file was located
done
_DIR="$( cd -P "$( dirname "$_SOURCE" )" && pwd )"

if [ ! -f $_DIR/helpers/common.sh ]; then
  echo -e "Missing helpers/common.sh file."
  exit 1
fi
source $_DIR/helpers/common.sh

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
  ${_ME} [list | install (= download + setup) | download | setup | delete] [DISTRIBUTION] [mysql (default) | postgres]
  ${_ME} install drupal
  ${_ME} install drupal mysql
    Install Drupal standard with MySQL.
  ${_ME} install drupal postgres
    Install Drupal standard with PgSQL.

Options:
  -h --help  Show this screen.
HEREDOC
printf "\\n"
_distributions_list
}

###############################################################################
# Program Functions
###############################################################################

# _install()
#
# Description:
#   Main install dispatcher.
_install() {

  if [[ ${_SELECTED_PROJECT} == 0 ]]
  then
    _select_project
  fi

  __do_download=${1:-1}
  __do_setup=${2:-1}

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

    if [[ ${_SELECTED_PROJECT} == ${__DID} ]]
    then
      if [[ $__do_download == 1 ]]
      then
        _download $__DOWNLOAD_TYPE
        _fix_docroot
      fi

      if [[ $__do_setup == 1 ]]
      then
        _setup $__SETUP_TYPE
        _fix_files_perm
      fi
    fi
  done

  exit
}

# _download()
#
# Description:
#   Download dispatcher depending download type of the project (composer or git).
_download() {
  printf "[info] Start downloading %s, this takes a while...\\n" "${__PROJECT}"
  __call="_download_$1"
  $__call
}

# _download_composer()
#
# Description:
#   Download with composer create-project command.
_download_composer() {
  # Setup Drupal 8 composer project.
  if [ -x "$(command -v composer)" ]; then
    composer create-project ${__PROJECT} ${HOST_WEB_ROOT}/${DRUPAL_SUBROOT} --no-interaction --no-ansi --ignore-platform-reqs --remove-vcs --no-progress --prefer-dist
  else
    _docker_exec_noi \
      composer create-project ${__PROJECT} ${DRUPAL_ROOT} --no-interaction --no-ansi --remove-vcs --no-progress --prefer-dist
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

  curl --silent --output download-contenta.sh "https://raw.githubusercontent.com/contentacms/contenta_jsonapi_project/8.x-2.x/scripts/download.sh"

  # Move to the container and set permission.
  $_DOCKER cp download-contenta.sh "${PROJECT_CONTAINER_NAME}":/tmp/download-contenta.sh
  _docker_exec_noi_u \
    chmod a+x /tmp/download-contenta.sh

  # Contenta script require a new folder.
  _docker_exec_noi \
    sh -c 'exec '"/tmp/download-contenta.sh"' '"/tmp/contenta"''
  _docker_exec_noi \
    cp -R /tmp/contenta/. ${DRUPAL_ROOT}/

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
  curl -fsSL "${__PROJECT}" -o drupal.tar.gz
  tar -xzf drupal.tar.gz -C ${HOST_WEB_ROOT}
  mv ${HOST_WEB_ROOT}/drupal-composer-advanced-template-8.x-dev ${HOST_WEB_ROOT}/${DRUPAL_SUBROOT}

  _docker_exec_noi_u \
    chown -R ${PROJECT_UID}:${PROJECT_UID} ${WEB_ROOT}

  # Cleanup.
  rm -f drupal.tar.gz

  # Setup Drupal 8 composer project.
  if [ -x "$(command -v composer)" ]; then
    composer install --working-dir="${HOST_WEB_ROOT}/${DRUPAL_SUBROOT}" --no-suggest --no-interaction --ignore-platform-reqs
  else
  
    # Fix composer cache because we are root. Fix www folder.
    _docker_exec_noi_u \
      mkdir -p /.composer/cache

    _docker_exec_noi_u \
      chown -R ${PROJECT_UID}:${PROJECT_UID} /.composer

    _docker_exec_noi \
      composer install --working-dir="${DRUPAL_ROOT}" --no-suggest --no-interaction 
  fi

  if [ -x "$(command -v composer)" ]; then
    composer install-boostrap-sass --working-dir="${HOST_WEB_ROOT}/${DRUPAL_SUBROOT}"
  else
    _docker_exec_noi \
      composer install-boostrap-sass --working-dir="${DRUPAL_ROOT}"
  fi

  if [ -x "$(command -v compass)" ]; then
    compass compile ${HOST_WEB_ROOT}/${DRUPAL_SUBROOT}/web/themes/custom/bootstrap_sass
  else
    printf "[warning] Compile manually from your Drupal code root:\\ncompass compile web/themes/custom/bootstrap_sass"
  fi
}

# _setup()
#
# Description:
#   Setup dispatcher depending Drupal profile name.
_setup() {
  printf "[info] Install %s with profile %s on db %s\\n" "${__DID}" "${__INSTALL_PROFILE}" "${DB_DRIVER}://${DB_USER}:${DB_PASSWORD}@${DB_HOST}/${DB_NAME}"

  _clean_setup
  _ensure_drush

  __call="_setup_$1"
  $__call

  printf "\\n >> Access %s on\\nhttp://${PROJECT_BASE_URL}\\n >> Log-in with: admin / password\\n\\n" "${__DID}"
}

# _clean_setup()
#
# Description:
#   Helper to ensure we don't have an existing setup.
_clean_setup() {
  _docker_exec_noi \
    rm -f "${DRUPAL_ROOT}/web/sites/dfault/settings.php"
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
  printf "[warning] Varbase profile can not be installed from drush, install from \\nhttp://${PROJECT_BASE_URL}\\n"
}

# _setup_contenta()
#
# Description:
#   Specific Contenta setup, use .env and drush.
_setup_contenta() {
  # http://www.contentacms.org/#install
  if [ -f "${HOST_WEB_ROOT}/${DRUPAL_SUBROOT}/.env" ]; then
    rm -f "${HOST_WEB_ROOT}/${DRUPAL_SUBROOT}/.env"
  fi
  if [ -f "${HOST_WEB_ROOT}/${DRUPAL_SUBROOT}/.env.local" ]; then
    rm -f "${HOST_WEB_ROOT}/${DRUPAL_SUBROOT}/.env.local"
  fi

  cp "${HOST_WEB_ROOT}/${DRUPAL_SUBROOT}/.env.example" "${HOST_WEB_ROOT}/${DRUPAL_SUBROOT}/.env"
  cp "${HOST_WEB_ROOT}/${DRUPAL_SUBROOT}/.env.local.example" "${HOST_WEB_ROOT}/${DRUPAL_SUBROOT}/.env.local"

  echo "SITE_MAIL=admin@localhost" >>"${HOST_WEB_ROOT}/${DRUPAL_SUBROOT}/.env"
  echo "ACCOUNT_MAIL=admin@localhost" >> "${HOST_WEB_ROOT}/${DRUPAL_SUBROOT}/.env"
  echo "SITE_NAME='Contenta CMS'" >> "${HOST_WEB_ROOT}/${DRUPAL_SUBROOT}/.env"
  echo "ACCOUNT_NAME=admin" >> "${HOST_WEB_ROOT}/${DRUPAL_SUBROOT}/.env"
  echo "MYSQL_DATABASE=$DB_NAME" >> "${HOST_WEB_ROOT}/${DRUPAL_SUBROOT}/.env"
  echo "MYSQL_HOSTNAME=$DB_HOST" >> "${HOST_WEB_ROOT}/${DRUPAL_SUBROOT}/.env"
  echo "MYSQL_USER=$DB_USER" >> "${HOST_WEB_ROOT}/${DRUPAL_SUBROOT}/.env"
  echo "MYSQL_PASSWORD=$DB_PASSWORD" >> "${HOST_WEB_ROOT}/${DRUPAL_SUBROOT}/.env.local"
  echo "ACCOUNT_PASS=password" >> "${HOST_WEB_ROOT}/${DRUPAL_SUBROOT}/.env.local"

  _docker_exec_noi \
    composer --working-dir="${DRUPAL_ROOT}" run-script install:with-mysql
}

# _setup_advanced()
#
# Description:
#   Specific install for advanced template with .env and drush.
_setup_advanced() {

  cp ${HOST_WEB_ROOT}/${DRUPAL_SUBROOT}/.env.example ${HOST_WEB_ROOT}/${DRUPAL_SUBROOT}/.env

  echo "MYSQL_DATABASE=$DB_NAME" >> "${HOST_WEB_ROOT}/${DRUPAL_SUBROOT}/.env"
  echo "MYSQL_HOSTNAME=$DB_HOST" >> "${HOST_WEB_ROOT}/${DRUPAL_SUBROOT}/.env"
  echo "MYSQL_USER=$DB_USER" >> "${HOST_WEB_ROOT}/${DRUPAL_SUBROOT}/.env"
  echo "MYSQL_PASSWORD=$DB_PASSWORD" >> "${HOST_WEB_ROOT}/${DRUPAL_SUBROOT}/.env"

  cp ${HOST_WEB_ROOT}/${DRUPAL_SUBROOT}/example.settings.php ${HOST_WEB_ROOT}/${DRUPAL_SUBROOT}/web/sites/default/settings.php
  cp ${HOST_WEB_ROOT}/${DRUPAL_SUBROOT}/example.settings.local.php ${HOST_WEB_ROOT}/${DRUPAL_SUBROOT}/web/sites/default/settings.local.php
  cp ${HOST_WEB_ROOT}/${DRUPAL_SUBROOT}/example.settings.dev.php ${HOST_WEB_ROOT}/${DRUPAL_SUBROOT}/web/sites/default/settings.dev.php
  cp ${HOST_WEB_ROOT}/${DRUPAL_SUBROOT}/example.settings.prod.php ${HOST_WEB_ROOT}/${DRUPAL_SUBROOT}/web/sites/default/settings.prod.php

  # Fix permission.
  _docker_exec_noi_u \
    chown -R ${PROJECT_UID}:${PROJECT_UID} ${DRUPAL_ROOT}/web/sites/default/

  # Install this profile with config_installer
  _docker_exec_noi "${DRUSH_BIN}" -y site:install "${__INSTALL_PROFILE}" \
    config_installer_sync_configure_form.sync_directory="../config/sync" \
    --root="${DRUPAL_DOCROOT}" \
    --account-pass="password" \
    --db-url="${DB_DRIVER}://${DB_USER}:${DB_PASSWORD}@${DB_HOST}/${DB_NAME}"
}

_ensure_drush() {
  if ! [ -f "${HOST_WEB_ROOT}/${DRUPAL_SUBROOT}/vendor/drush/drush/drush" ]; then
    printf "[info] Install missing drush\\n"
    # Drush is not included in varbase distribution.
    if [ -x "$(command -v composer)" ]; then
      composer require drush/drush --working-dir="${HOST_WEB_ROOT}/${DRUPAL_SUBROOT}" --ignore-platform-reqs -vv
    else
      _docker_exec_noi \
        composer require drush/drush --working-dir="${DRUPAL_ROOT}" -vv
    fi
  fi
}

# _select_project()
#
# Description:
#   Helper to let user select a project for this script.
_select_project() {

  printf "For more information on each option run ${_ME} list\\n"

  __list=()
  __COUNT=${#DRUPAL_DISTRIBUTIONS[@]}
  for ((i=0; i<$__COUNT; i++))
  do
    __list[i]=${!DRUPAL_DISTRIBUTIONS[i]:0:1}
  done

  select opt in "${__list[@]}"; do
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
  if [ ! -z "$RUNNING" ]; then
    _DB_LIST[0]="mariadb"
  fi

  # Check if any mysql container is running.
  RUNNING=$(docker ps -f "name=mysql" -f "status=running" -q | head -1 2> /dev/null)
  if [ ! -z "$RUNNING" ]; then
    _DB_LIST[0]="mysql"
  fi

  # Check if any postgresql container is running.
  RUNNING=$(docker ps -f "name=pgsql" -f "status=running" -q | head -1 2> /dev/null)
  if [ ! -z "$RUNNING" ]; then
    _DB_LIST[1]="postgres"
  fi

  if [[ ${_DB_LIST} == 0 ]]
  then
    die "No database container found, please ensure your stack is running."
  fi

  if [[ ${_DB_LIST[0]} == $_DEFAULT_DB ]] || [[ ${_DB_LIST[1]} == $_DEFAULT_DB ]]
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

# _distributions_list()
#
# Description:
#   Helper to return the list of available distributions/profiles for this
#   script with description.
_distributions_list() {
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
      ln -s ${DRUPAL_ROOT}/${__WEBROOT} ${DRUPAL_ROOT}/web
  fi
}

# _fix_files_perm()
#
# Description:
#   Helper to fix Drupal permission hardly.
_fix_files_perm() {
  _docker_exec_noi_u \
    mkdir -p ${DRUPAL_ROOT}/web/sites/default/files/tmp
  _docker_exec_noi_u \
    mkdir -p ${DRUPAL_ROOT}/web/sites/default/files/private
  _docker_exec_noi_u \
    chmod -R 777 ${DRUPAL_ROOT}/web/sites/default/files
  _docker_exec_noi_u \
    chown -R ${PROJECT_UID}:${PROJECT_UID} ${DRUPAL_ROOT}/web/sites/default/files
  # contenta specific.
  if [[ ${__DID} == "contenta" ]]
  then
    _docker_exec_noi_u \
      chmod -R 660 ${DRUPAL_ROOT}/keys/public.key
  fi
  _docker_exec_noi_u \
    chmod -R 777 /tmp
}

# _nuke()
#
# Description:
#   Delete a previous downloaded Drupal.
_nuke() {
  _prompt_yn
  sudo rm -rf $HOST_WEB_ROOT/$DRUPAL_SUBROOT
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

  _SELECTED_PROJECT=${2:-0}
  _DEFAULT_DB=${3:-"mysql"}

  if [[ "${1:-}" =~ ^install$ ]]
  then
    _install
  elif [[ "${1:-}" =~ ^list$ ]]
  then
    _distributions_list
  elif [[ "${1:-}" =~ ^download$ ]]
  then
    _install 1 0
  elif [[ "${1:-}" =~ ^setup$ ]]
  then
    _install 0 1
  elif [[ "${1:-}" =~ ^delete$ ]]
  then
    _nuke
  else
    _print_help
  fi
}

# Call `_main` after everything has been defined.
_main "$@"
