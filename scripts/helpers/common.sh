#!/usr/bin/env bash
# Helper to have common bash settings for most of the scripts.
# Based on Bash simple Boilerplate.
# https://github.com/Mogtofu33/docker-compose-drupal
#
# Bash Boilerplate: https://github.com/alphabetum/bash-boilerplate
# Bash Boilerplate: Copyright (c) 2015 William Melody • hi@williammelody.com

set -o nounset
set -o errexit
trap 'echo "Aborting due to errexit on line $LINENO. Exit code: $?" >&2' ERR
set -o errtrace
set -o pipefail
IFS=$'\n\t'

###############################################################################
# Environment
###############################################################################

# $_ME
#
# Set to the program's basename.
_ME=$(basename "${0}")

# $_SOURCE
#
# Set to the program's source.
_SOURCE="${BASH_SOURCE[0]}"

while [ -h "$_SOURCE" ]; do
  _DIR="$( cd -P "$( dirname "$_SOURCE" )" && pwd )"
  _SOURCE="$(readlink "$_SOURCE")"
  [[ $_SOURCE != /* ]] && _SOURCE="$_DIR/$_SOURCE"
done
_DIR="$( cd -P "$( dirname "$_SOURCE" )" && pwd )"

# Use on a lot of scripts.
STACK_ROOT=${_DIR%"/scripts/helpers"}

###############################################################################
# Die
###############################################################################

# _die()
#
# Usage:
#   _die printf "Error message. Variable: %s\n" "$0"
#
# A simple function for exiting with an error after executing the specified
# command. The command is expected to print a message and should typically
# be either `echo`, `printf`, or `cat`.
_die() {
  # Prefix die message with "cross mark (U+274C)", often displayed as a red x.
  printf "❌  "
  "${@}" 1>&2
  exit 1
}
# die()
#
# Usage:
#   die "Error message. Variable: $0"
#
# Exit with an error and print the specified message.
#
# This is a shortcut for the _die() function that simply echos the message.
die() {
  _die echo "${@}"
}

###############################################################################
# Variables
###############################################################################

# Get Stack values if any.
if [ -f $STACK_ROOT/.env ]; then
  source $STACK_ROOT/.env
fi

if [ -f $STACK_ROOT/.env.local ]; then
  source $STACK_ROOT/.env.local
fi

# Get scripts values.
if [ -f $_DIR/../.env ]; then
  source $_DIR/../.env
fi

STACK_DRUPAL_ROOT=${STACK_ROOT}/${HOST_WEB_ROOT#'./'}

# Basic variables.
NOW="$(date +'%Y%m%d.%H-%M-%S')"
tty=
tty -s && tty=--tty

if ! [ -x "$(command -v docker)" ]; then
  printf "[notice] docker not found and is probably required for this script.\\n"
  DOCKER=""
else
  DOCKER=$(which docker)
fi

if ! [ -x "$(command -v docker-compose)" ]; then
  printf "[notice] docker-compose not found and is probably required for this script.\\n"
  DOCKER_COMPOSE=""
else
  DOCKER_COMPOSE=$(which docker-compose)
fi

PROJECT_CONTAINER_PHP="${PROJECT_NAME}-php"

###############################################################################
# Common Program Functions
###############################################################################

# Helpers to run docker exec command on Php.
_docker_exec() {
  $DOCKER exec \
    $tty \
    --interactive \
    --user ${LOCAL_UID} \
    ${PROJECT_CONTAINER_PHP} "$@"
}

_docker_exec_noi() {
  $DOCKER exec \
    $tty \
    --user ${LOCAL_UID} \
    ${PROJECT_CONTAINER_PHP} "$@"
}

_docker_exec_root() {
  $DOCKER exec \
    ${PROJECT_CONTAINER_PHP} "$@"
}

# Helper to ensure mysql container is runing.
_set_container_mysql() {
  RUNNING=$(docker ps -f "name=mariadb" -f "name=mysql" -f "status=running" -q | head -1 2> /dev/null)
  if [ -z "$RUNNING" ]; then
    die "No running MySQL container found, did you run docker-compose up -d ?"
  else
    PROJECT_CONTAINER_MYSQL=$(docker inspect --format="{{ .Name }}" $RUNNING)
    PROJECT_CONTAINER_MYSQL="${PROJECT_CONTAINER_MYSQL///}"
  fi
}

# Helper to ensure postgres container is runing.
_set_container_pgsql() {
  RUNNING=$(docker ps -f "name=pgsql" -f "status=running" -q | head -1 2> /dev/null)
  if [ -z "$RUNNING" ]; then
    die "No running PGSQL container found, did you run docker-compose up -d ?"
  else
    PROJECT_CONTAINER_PGSQL=$(docker inspect --format="{{ .Name }}" $RUNNING)
    PROJECT_CONTAINER_PGSQL="${PROJECT_CONTAINER_PGSQL///}"
  fi
}

# _stack_down()
#
# Description:
#   Run docker-compose down.
_stack_down() {
  printf "[info] Stop stack...\\n"
  $DOCKER_COMPOSE --file "${STACK_ROOT}/docker-compose.yml" down
}

# _stack_up()
#
# Description:
#   Run docker-compose up with build.
_stack_up() {
  printf "[info] Launch stack...\\n"
  $DOCKER_COMPOSE --file "${STACK_ROOT}/docker-compose.yml" up -d --build
}

###############################################################################
# Utility Functions
###############################################################################

# A logo, because it's cool.
_help_logo() {
  cat <<HEREDOC
   ___  _____  __  __  ____    ___   ___  ____  ____  ____  ____  ___  
  / __)(  _  )(  \/  )( ___)  / __) / __)(  _ \(_  _)(  _ \(_  _)/ __) 
  \__ \ )(_)(  )    (  )__)   \__ \( (__  )   / _)(_  )___/  )(  \__ \ 
  (___/(_____)(_/\/\_)(____)  (___/ \___)(_)\_)(____)(__)   (__) (___/ 
HEREDOC
}

###############################################################################
# _prompt_yn()
#
# Description:
#   Display a simple yes/no prompt and stop if no.
_prompt_yn() {
  printf "%s\\n" "$@"
  read -p "Are you sure? (y/n) " -n 1 -r
  echo
  if [[ ! $REPLY =~ ^[Yy]$ ]]
  then
      die "Canceled"
  fi
}

###############################################################################
# _spinner()
#
# Usage:
#   _spinner <pid>
#
# Description:
#   Display an ascii spinner while <pid> is running.
#
# Example Usage:
#   ```
#   _spinner_example() {
#     printf "Working..."
#     (sleep 1) &
#     _spinner $!
#     printf "Done!\n"
#   }
#   (_spinner_example)
#   ```
#
# More Information:
#   http://fitnr.com/showing-a-bash-spinner.html
_spinner() {
  local _pid="${1:-}"
  local _delay=0.75
  local _spin_string="|/-\\"

  if [[ -z "${_pid}" ]]
  then
    printf "Usage: _spinner <pid>\\n"
    return 1
  fi

  while ps a | awk '{print $1}' | grep -q "${_pid}"
  do
    local _temp="${_spin_string#?}"
    printf " [%c]  " "${_spin_string}"
    _spin_string="${_temp}${_spin_string%${_temp}}"
    sleep ${_delay}
    printf "\\b\\b\\b\\b\\b\\b"
  done
  printf "    \\b\\b\\b\\b"
}
