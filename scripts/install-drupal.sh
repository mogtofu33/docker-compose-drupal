#!/usr/bin/env bash
#
# Download and install Drupal 8 projects for DockerComposeDrupal.
#
# Usage:
#   install.sh list | install
#
# Depends on:
#  docker
#  docker-compose
#  DockerComposeDrupal
#
# Inspiration from Bash Boilerplate: https://github.com/alphabetum/bash-boilerplate
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
  list | l          List available projects.
  install | i       Download + Setup a project in one command.
  download | dl     Download a project codebase as a single command.
  setup | set       Setup a Drupal project as a single command.
  delete            Delete a previously downloaded project.

Options with argument:
  -p --project      Optional project name, if not set select prompt.
  -d --database     Database service: postgres or mysql, default "mysql"

Options:
  -dp --profile     Force Drupal profile installation.
  -f --force        Force prompt with Yes if any.
  -v --verbose      More messages with this scripts.
  -q --quiet        Produce less messages.
  --debug           Debug messages.
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
_DRUPAL_PROFILE=0
_DEFAULT_DB="mysql"

__force=0
__verbose=""
__verbose_drush=""
__quiet=""
__do_download=0
__do_setup=0
__login_help=1
__composer_local=
__composer_options=""

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
      __verbose_drush="-v"
      debug "-v specified: Verbose mode"
      ;;
    -q|--quiet)
      __quiet="--quiet"
      debug "-q specified: Quiet mode"
      ;;
    --debug)
      _USE_DEBUG=1
      debug "Debug mode is ON"
      ;;
    -p|--project)
      _require_argument "${__option}" "${__maybe_param}"
      _SELECTED_PROJECT="${__maybe_param}"
      shift
      ;;
    -dp|--profile)
      _require_argument "${__option}" "${__maybe_param}"
      _DRUPAL_PROFILE="${__maybe_param}"
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
_i() {
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
  __DID=0
  __DID_FOUND=0

  for ((i=0; i<$__COUNT; i++))
  do

    __DID=${!DRUPAL_DISTRIBUTIONS[i]:0:1}

    if [[ ${_SELECTED_PROJECT} == "${__DID}" ]]
    then
      __DID_FOUND=1
      __DESC=${!DRUPAL_DISTRIBUTIONS[i]:1:1}
      __INSTALL_PROFILE=${!DRUPAL_DISTRIBUTIONS[i]:2:1}
      __WEBROOT=${!DRUPAL_DISTRIBUTIONS[i]:3:1}
      __DOWNLOAD_TYPE=${!DRUPAL_DISTRIBUTIONS[i]:4:1}
      __PROJECT=${!DRUPAL_DISTRIBUTIONS[i]:5:1}
      __SETUP_TYPE=${!DRUPAL_DISTRIBUTIONS[i]:6:1}

      # Force profile.
      if [[ ${_DRUPAL_PROFILE} != 0 ]]
      then
        __INSTALL_PROFILE=${_DRUPAL_PROFILE}
      fi

      if [[ $__do_download == 1 ]]
      then
        debug "_download_dispatch $__DOWNLOAD_TYPE"
        _download_dispatch "$__DOWNLOAD_TYPE"
      fi

      if [[ $__do_setup == 1 ]]
      then
        debug "_setup_dispatch $__SETUP_TYPE"
        _setup_dispatch "$__SETUP_TYPE"
      fi
    fi
  done

  if [[ ${__DID_FOUND} == 0 ]]
  then
    log_error "Unknown project: ${_SELECTED_PROJECT}"
    printf "\\nTo have a list of available projects run:\\n%s list\\n\\n" "${_ME}"
    exit 1
  fi

}

# _download_dispatch()
#
# Description:
#   Download dispatcher depending download type of the project (composer or git).
_download_dispatch() {
  # Delete any existing codebase.
  _delete

  log_info "Start downloading ${__PROJECT}"
  __call="_download_${1}"
  debug "call $__call"
  $__call
  log_success "Finished downloading ${__PROJECT}"

  # Restart container with web access.
  _stack_restart

  _fix_docroot
}

# _download_composer()
#
# Description:
#   Download with composer create-project command.
#   Accept composer options as argument.
_download_composer() {

  # Set and extend composer options.
  __composer_options="--no-interaction --no-ansi --remove-vcs --no-progress --prefer-dist ${__quiet} ${__verbose}"
  __composer_options_local="${__composer_options} --ignore-platform-reqs"

  if [[ ! -z ${1+x} ]]
  then
    __composer_options="${__composer_options} ${1}"
    __composer_options_local="${__composer_options_local} ${1}"
  fi

  # Setup Drupal 8 composer project.
  if [ -x "$(command -v composer)" ]; then
    if [[ ${__quiet} == "" ]]
    then
      log_info "Found composer installed locally"
    fi
    debug "COMPOSER_MEMORY_LIMIT=-1 composer create-project $__PROJECT $STACK_DRUPAL_ROOT $__composer_options_local"
    bash -c "COMPOSER_MEMORY_LIMIT=-1 composer create-project $__PROJECT $STACK_DRUPAL_ROOT $__composer_options_local"
  else
    if [[ ${__quiet} == "" ]]
    then
      log_info "No local composer found, using composer from the stack"
    fi

    # Delete existing tmp.
    _docker_exec_root \
      rm -Rf /tmp/drupal

    debug "docker exec ... COMPOSER_MEMORY_LIMIT=-1 composer create-project ${__PROJECT} /tmp/drupal $__composer_options"

    # Download and move as create-project needs a new folder.
    _docker_exec_noi \
      bash -c "COMPOSER_MEMORY_LIMIT=-1 composer create-project ${__PROJECT} /tmp/drupal $__composer_options"

    _docker_exec_root \
      chown $LOCAL_UID:$LOCAL_GID ${WEB_ROOT}
    _docker_exec_noi \
      cp -Rp /tmp/drupal/. ${WEB_ROOT}
    _docker_exec_root \
      rm -Rf /tmp/drupal
  fi
}

# _download_composer_commerce()
#
# Description:
#   Download with composer create-project command for Commerce.
_download_composer_commerce() {
  # Commerce currently needs the dev stability forced to be installed.
  _download_composer "--stability dev"
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

  debug "Get Contenta download script: https://raw.githubusercontent.com/contentacms/contenta_jsonapi_project/8.x-2.x/scripts/download.sh"

  if [[ ${__verbose} == "" ]] || [[ ${__quiet} == "--quiet" ]]
  then
    curl --silent --output download-contenta.sh "https://raw.githubusercontent.com/contentacms/contenta_jsonapi_project/8.x-2.x/scripts/download.sh"
  else
    curl --output download-contenta.sh "https://raw.githubusercontent.com/contentacms/contenta_jsonapi_project/8.x-2.x/scripts/download.sh"
  fi

  # Move to the container and set permission.
  $DOCKER cp download-contenta.sh ${PROJECT_CONTAINER_PHP}:/tmp/download-contenta.sh
  _docker_exec_root \
    chmod a+x /tmp/download-contenta.sh

  debug "Run script and move downloaded files"

  # Contenta script require a new folder.
  _docker_exec_noi \
    sh -c 'exec '"/tmp/download-contenta.sh"' '"/tmp/contenta"''

  _docker_exec_root \
    chown $LOCAL_UID:$LOCAL_GID ${WEB_ROOT}
  _docker_exec_noi \
    cp -Rp /tmp/contenta/. ${WEB_ROOT}

  # Re-install for patches.
  _composer_cmd "install --no-suggest --no-interaction"

  # Cleanup.
  _docker_exec_root \
    rm -Rf /tmp/contenta /tmp/download-contenta.sh

  rm -f "download-contenta.sh"
}

# _download_curl()
#
# Description:
#   Download with curl based on an url with a tar.gz archive.
_download_curl() {

  debug "_download_curl ${__PROJECT}"

  # Download the archive and extract.
  if [[ ${__quiet} == "" ]]
  then
    curl -fSL "${__PROJECT}" -o ${STACK_ROOT}/drupal.tar.gz
  else
    curl -fsSL "${__PROJECT}" -o ${STACK_ROOT}/drupal.tar.gz
  fi

  _delete

  docker cp ${STACK_ROOT}/drupal.tar.gz ${PROJECT_CONTAINER_PHP}:/tmp

  _docker_exec_root \
    tar -xz --strip-components=1 -C ${WEB_ROOT} -f /tmp/drupal.tar.gz

  _docker_exec_root \
    chown -R ${LOCAL_UID}:${LOCAL_GID} ${WEB_ROOT}

  # If no web root, symlink.
  if [[ ${__WEBROOT} == "" ]]
  then
    debug "Webroot not here, create symlink"
    _docker_exec_root \
      ln -s ${WEB_ROOT} ${DRUPAL_DOCROOT}
  fi

  # Cleanup.
  rm -f ${STACK_ROOT}/drupal.tar.gz

  # Setup Drupal 8 composer project.
  if [[ -f ${STACK_ROOT}/composer.json ]]
  then
    _composer_cmd "install --no-suggest --no-interaction"
  fi
}

#
# Description:
#   Setup dispatcher depending Drupal profile name.
_setup_dispatch() {

  log_info "Setup ${__DID} with profile \e[3m\e[1m${__INSTALL_PROFILE}\e[0m on db ${DB_DRIVER}://${DB_USER}:${DB_PASSWORD}@${DB_HOST}/${DB_NAME}"

  _ensure_drush
  __call="_setup_${1}"
  $__call
  _fix_files_perm

  log_success "Profile ${__INSTALL_PROFILE} with ${__DID} installed"

  if [[ ${__login_help} == 1 ]] && [[ ${__quiet} == "" ]]
  then
    printf "\\n >> Access %s on\\nhttp://${PROJECT_BASE_URL}\\n >> Log-in with: admin / password\\n\\n" "${__DID}"
  fi
}

# _setup_standard()
#
# Description:
#   Setup with Drush for a specific profile.
_setup_standard() {

  debug "Install profile ${__INSTALL_PROFILE} with generic setup"

  # Install this profile.
  _docker_exec_noi "${DRUSH_BIN}" ${__verbose_drush} ${__quiet} -y site:install ${__INSTALL_PROFILE} \
    --root="${DRUPAL_DOCROOT}" \
    --account-pass="password" \
    --db-url="${DB_DRIVER}://${DB_USER}:${DB_PASSWORD}@${DB_HOST}/${DB_NAME}" \
    --site-name="My Drupal 8 ${__INSTALL_PROFILE} on DcD"
}

# _setup_varbase()
#
# Description:
#   Specific Varbase setup, can not be done with Drush, but add Drush for dev.
#   The problem is the Varbase install form with many options.
_setup_varbase() {
  if [[ ${__quiet} == "" ]]
  then
    log_warn "Varbase profile has too many options and can not be installed with this script"
    printf "Please install from \\nhttp://%s\\n" "${PROJECT_BASE_URL}"
  fi
  __login_help=0
}

# _setup_contenta()
#
# Description:
#   Specific Contenta setup, use .env and drush.
_setup_contenta() {

  debug "Populate Contenta .env"

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

  debug "Install Contenta with included script"

  _docker_exec_noi \
    composer --working-dir="${WEB_ROOT}" run-script install:with-mysql ${__verbose} ${__quiet}
}

# _setup_advanced()
#
# Description:
#   Specific install for advanced template with .env and drush.
_setup_advanced() {

  debug "Populate .env file and copy settings"

  cp "${STACK_DRUPAL_ROOT}/.env.example" "${STACK_DRUPAL_ROOT}/.env"

  echo "MYSQL_DATABASE=$DB_NAME" >> "${STACK_DRUPAL_ROOT}/.env"
  echo "MYSQL_HOSTNAME=$DB_HOST" >> "${STACK_DRUPAL_ROOT}/.env"
  echo "MYSQL_USER=$DB_USER" >> "${STACK_DRUPAL_ROOT}/.env"
  echo "MYSQL_PASSWORD=$DB_PASSWORD" >> "${STACK_DRUPAL_ROOT}/.env"

  cp ${STACK_DRUPAL_ROOT}/example.settings.local.php ${STACK_DRUPAL_ROOT}/web/sites/default/settings.local.php
  cp ${STACK_DRUPAL_ROOT}/example.settings.dev.php ${STACK_DRUPAL_ROOT}/web/sites/default/settings.dev.php
  cp ${STACK_DRUPAL_ROOT}/example.settings.prod.php ${STACK_DRUPAL_ROOT}/web/sites/default/settings.prod.php

  # Fix permission.
  _docker_exec_root \
    chown -R ${LOCAL_UID}:${LOCAL_GID} ${DRUPAL_DOCROOT}/sites/default/

  debug "Install this profile with ${__INSTALL_PROFILE}"

  # Install this profile with config_installer
  _docker_exec_noi "${DRUSH_BIN}" ${__verbose_drush} ${__quiet} -y site:install "${__INSTALL_PROFILE}" \
    config_installer_sync_configure_form.sync_directory="../config/sync" \
    --root="${DRUPAL_DOCROOT}" \
    --account-pass="password" \
    --db-url="${DB_DRIVER}://${DB_USER}:${DB_PASSWORD}@${DB_HOST}/${DB_NAME}"

  # After installation copy our settings file.
  _docker_exec_root \
    chmod 777 ${DRUPAL_DOCROOT}/sites/default/settings.php
  _docker_exec_root \
    chmod 750 ${DRUPAL_DOCROOT}/sites/default
  echo 'include $app_root . "/" . $site_path . "/settings.local.php";' >> ${STACK_DRUPAL_ROOT}/web/sites/default/settings.php

  _docker_exec_noi "${DRUSH_BIN}" ${__verbose_drush} ${__quiet} -y csim config_split.config_split.config_dev
}

# _setup_commerce_demo()
#
# Description:
#   Specific install for commerce with demo modules.
_setup_commerce_demo() {

  _setup_standard

  # Add commerce demo module.
  log_info "Extend commerce with commerce_demo"
  _composer_cmd "require drupal/commerce_demo bower-asset/jquery-simple-color drupal/belgrade"

  debug "${DRUSH_BIN} ${__verbose_drush} ${__quiet} -y pm:enable commerce_demo"

  _docker_exec_noi "${DRUSH_BIN}" ${__verbose_drush} ${__quiet} -y pm:enable commerce_demo
  _docker_exec_noi "${DRUSH_BIN}" ${__verbose_drush} ${__quiet} -y theme:enable belgrade
  _docker_exec_noi "${DRUSH_BIN}" ${__verbose_drush} ${__quiet} -y config-set system.theme default belgrade
  _docker_exec_noi "${DRUSH_BIN}" ${__verbose_drush} ${__quiet} -y config-set system.site page.front /products
}

# _ensure_drush()
#
# Description:
#   Helper to detect and add Drush if needed as it's not included in some
#   projects.
_ensure_drush() {
  debug "Check and ensure Drush"
  if ! [ -f "${STACK_DRUPAL_ROOT}/vendor/drush/drush/drush" ]; then
    log_info "Install drush"
    # Drush is not included in all distributions.
    _composer_cmd "require drush/drush"
  fi
}

# _composer_cmd()
#
# Description:
#   Helper to run composer command, need the command and parameters as first argument.
_composer_cmd() {
  if [ -x "$(command -v composer)" ]; then
    if [[ ${__quiet} == "" ]]
    then
      log_info "Found composer installed locally"
    fi
    bash -c "COMPOSER_MEMORY_LIMIT=-1 composer ${1} --working-dir=${STACK_DRUPAL_ROOT} --ignore-platform-reqs"
  else
    if [[ ${__quiet} == "" ]]
    then
      log_info "No local composer found, using composer from the stack"
    fi
    _docker_exec_noi \
      bash -c "COMPOSER_MEMORY_LIMIT=-1 composer ${1} --working-dir=${WEB_ROOT}"
  fi
}

# _select_project()
#
# Description:
#   Helper to let user select a project for this script.
_select_project() {

  log_info "For more information on each option run ${_ME} list"

  __list=()
  __COUNT=${#DRUPAL_DISTRIBUTIONS[@]}
  for ((i=0; i<$__COUNT; i++))
  do
    __list[i]="${!DRUPAL_DISTRIBUTIONS[i]:0:1} - ${!DRUPAL_DISTRIBUTIONS[i]:1:1}"
  done

  select opt in "${__list[@]}" "Cancel"; do
    case $opt in
      Cancel) die Cancelled;;
      *)
        _SELECTED_PROJECT=${opt% - *}
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
    debug "Found container mariadb running."
    _DB_LIST[0]="mariadb"
  fi

  # Check if any mysql container is running.
  RUNNING=$(docker ps -f "name=mysql" -f "status=running" -q | head -1 2> /dev/null)
  if [[ -n "$RUNNING" ]]
  then
    debug "Found container mysql running."
    _DB_LIST[0]="mysql"
  fi

  # Check if any postgresql container is running.
  RUNNING=$(docker ps -f "name=pgsql" -f "status=running" -q | head -1 2> /dev/null)
  if [[ -n "$RUNNING" ]]
  then
    debug "Found container postgres running."
    _DB_LIST[1]="postgres"
  fi

  if [[ ${_DB_LIST} == 0 ]]
  then
    if [[ ! -z ${_DB_ERROR+x} ]]
    then
      log_error "No database container found, ensure stack is running and a MySQL / MariaDB / Postgres container is running properly."
    else
      log_warn "No database container found, launching stack..."
      _DB_ERROR=1
      _stack_up
      _select_db
    fi
  fi

  if [[ ${_DB_LIST[0]} == "$_DEFAULT_DB" ]]
  then
    _DB=$_DEFAULT_DB
  fi

  if [[ ${#_DB_LIST[@]} > 1 ]]
  then
    if [[ ${_DB_LIST[1]} == "$_DEFAULT_DB" ]]
    then
      _DB=$_DEFAULT_DB
    fi
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
    if [[ -z ${_DB_ERROR+x} ]]
    then
      log_info "Using database \e[3m\e[1m${_DB}\e[0m"
    fi
  fi

  if [[ $_DB == "postgres" ]]
  then
    DB_DRIVER=pgsql
    DB_HOST=pgsql
  fi

  if [[ $_DB == 0 ]]
  then
    die "Cannot found a valid database, is a Mysql/Postgres container running ?"
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
_l() {
  _list
}

# _fix_docroot()
#
# Description:
#   Helper to fix Drupal web root, some projects use docroot, other web...
_fix_docroot() {
  debug "Fix docroot..."
  if [[ ${__WEBROOT} != "web" ]] && [[ ${__WEBROOT} != "" ]]
  then
    log_info "Fix Drupal ${WEB_ROOT}/${__WEBROOT} to ${DRUPAL_DOCROOT}"
    _docker_exec_noi \
      ln -s ${WEB_ROOT}/${__WEBROOT} ${DRUPAL_DOCROOT}
  fi
}

# _fix_files_perm()
#
# Description:
#   Helper to fix Drupal permission hardly.
_fix_files_perm() {
  debug "Fix files permissions..."

  if [[ ${__WEBROOT} == "" ]]
  then
    __DRUPAL_DOCROOT="${WEB_ROOT}"
  else
    __DRUPAL_DOCROOT="${DRUPAL_DOCROOT}"
  fi

  debug "Docroot is ${__DRUPAL_DOCROOT}"

  _docker_exec_root \
    mkdir -p ${__DRUPAL_DOCROOT}/sites/default/files/tmp
  _docker_exec_root \
    mkdir -p ${__DRUPAL_DOCROOT}/sites/default/files/private
  _docker_exec_root \
    chmod -R 777 ${__DRUPAL_DOCROOT}/sites/default/files
  _docker_exec_root \
    chown -R ${LOCAL_UID}:${LOCAL_GID} ${__DRUPAL_DOCROOT}/sites/default/files

  # contenta specific.
  if [[ ${__DID} == "contenta" ]]
  then
    _docker_exec_root \
      chmod -R 660 ${WEB_ROOT}/keys/public.key
  fi

  _docker_exec_root \
    chmod -R 777 /tmp
}

# _delete()
#
# Description:
#   Delete a previous downloaded Drupal.
_delete() {
  if [[ -d ${STACK_DRUPAL_ROOT}/web ]] || [[ -f ${STACK_DRUPAL_ROOT}/composer.json ]] || [[ -f ${STACK_DRUPAL_ROOT}/index.php ]]
  then
    if [[ ${__force} == 0 ]]
    then
      log_warn "Deletion is permanent and can not be recovered!"
      _prompt_yn "Do you want to proceed?"
    fi

    debug "Deleting codebase"

    _docker_exec_root \
      chown -R $LOCAL_UID:$LOCAL_GID "${WEB_ROOT}"

    debug "Stop call from _delete"
    _stack_stop

    debug "Delete drupal folder"
    chmod -R 777 "${STACK_DRUPAL_ROOT}"
    rm -Rf "${STACK_DRUPAL_ROOT}"

    debug "Start call from _delete"
    _stack_start

    debug "...Done"
  fi

  if [[ -d /tmp/drupal ]]
  then
    rm -Rf /tmp/drupal
  fi
}

_stack_restart() {
  debug "Restart php, apache"
  $DOCKER_COMPOSE --file "${STACK_ROOT}/docker-compose.yml" --log-level ERROR restart php apache
  sleep 15s
  debug "...Done"
}

_stack_stop() {
  debug "Stop php, apache"
  $DOCKER_COMPOSE --file "${STACK_ROOT}/docker-compose.yml" --log-level ERROR stop php apache
  debug "...Done"
}

_stack_start() {
  debug "Start php, apache"
  $DOCKER_COMPOSE --file "${STACK_ROOT}/docker-compose.yml" --log-level ERROR start php apache
  debug "Let stack script run..."
  sleep 15s
  debug "...Done"
}

###############################################################################
# Tests
###############################################################################

_test() {

  _CMD="test"
  _SELECTED_PROJECT=""
  _DEFAULT_DB="mysql"
  _DB="mysql"
  _USE_DEBUG=0

  __force=1
  __quiet="--quiet"

  __COUNT=${#DRUPAL_DISTRIBUTIONS[@]}

  for ((i=0; i<$__COUNT; i++))
  do

    __DID=${!DRUPAL_DISTRIBUTIONS[i]:0:1}
    _SELECTED_PROJECT=${__DID}
    __INSTALL_PROFILE=${!DRUPAL_DISTRIBUTIONS[i]:2:1}
    __WEBROOT=${!DRUPAL_DISTRIBUTIONS[i]:3:1}
    __DOWNLOAD_TYPE=${!DRUPAL_DISTRIBUTIONS[i]:4:1}
    __PROJECT=${!DRUPAL_DISTRIBUTIONS[i]:5:1}
    __SETUP_TYPE=${!DRUPAL_DISTRIBUTIONS[i]:6:1}

    if [ ${__DID} == "varbase" ] || [ ${__DID} == "social" ] || [ ${__DID} == "lightning" ] || [ ${__DID} == "thunder" ]; then
      log_success ">>>>>>>>>>>>> SKIPPING $_SELECTED_PROJECT <<<<<<<<<<<<<<<<<<<"
    else
      log_warn ">>>>>>>>>>>>> START TEST install $_SELECTED_PROJECT <<<<<<<<<<<<<<<<<<<"
      _download_dispatch "$__DOWNLOAD_TYPE"
      _setup_dispatch "$__SETUP_TYPE"
      _docker_exec_noi "${DRUSH_BIN}" ${__verbose_drush} core:status --fields=drupal-version,db-status
      log_success ">>>>>>>>>>>>> END TEST $_SELECTED_PROJECT <<<<<<<<<<<<<<<<<<<"
    fi

  done
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

    # Run command if exist.
    __call="_${_CMD}"
    if [ "$(type -t "${__call}")" == 'function' ]; then
      __start=`date +%s`
      debug "call $__call"
      $__call
      __end=`date +%s`
      __runtime=$((__end-__start))
      debug "Finished in ${__runtime} seconds"
    else
      log_error "Unknown command: ${_CMD}"
    fi

  fi

}

# Call `_main` after everything has been defined.
_main
