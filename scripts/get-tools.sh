#!/usr/bin/env bash
#
# Helper to get third party tools, part of Docker compose Drupal project.
# Based on Bash simple Boilerplate.
# https://github.com/Mogtofu33/docker-compose-drupal
#
# Usage:
#   get-tools install | update | delete
#
# Depends on:
#  git
#
# Bash Boilerplate: https://github.com/alphabetum/bash-boilerplate
# Bash Boilerplate: Copyright (c) 2015 William Melody • hi@williammelody.com

if [ -z ${STACK_ROOT} ]; then
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
Helper to get third party tools, part of Docker compose Drupal project.

Depends on:
  git

Usage:
  ${_ME} [install | update | delete]

Options:
  -h --help  Show this screen.
HEREDOC
}

###############################################################################
# Variables
###############################################################################

_PROGRAMS=(
  # "potsky/PimpMyLog.git:PimpMyLog"
  "wp-cloud/phpmemcacheadmin.git:PhpMemcachedAdmin"
  "amnuts/opcache-gui.git:Opcache-gui"
  "splitbrain/xdebug-trace-tree.git:Xdebug-trace"
  "dg/adminer-custom.git:adminerExtended"
  "ErikDubbelboer/phpRedisAdmin.git:phpRedisAdmin"
  "nrk/predis.git:phpRedisAdmin/vendor"
)
_CONFIG=(
  # "pimpmylog/config.user.php:PimpMyLog"
  "memcache/Memcache.php:PhpMemcachedAdmin/Config"
  "redis/config.inc.php:phpRedisAdmin/includes"
)

###############################################################################
# Program Functions
###############################################################################

_install() {
  printf "Install started, clone projects...\n"
  if [ ! -d "${_DIR}/../../tools" ]; then
    mkdir -p "${_DIR}/../../tools"
  fi
  for i in "${_PROGRAMS[@]:-}"
  do
    arr=($(echo "$i" | tr ':' "\n"))
    repo=${arr[0]}
    program=${arr[1]}
    if [ ! -d "${_DIR}/../../tools/${program}" ]
    then
      git clone "https://github.com/${repo:-}" "${_DIR}/../../tools/${program:-}"
    else
      printf "Program already installed, you should run update ?: %s\n" "${program}"
    fi
  done
  for i in "${_CONFIG[@]:-}"
  do
    arr=($(echo "$i" | tr ':' "\n"))
    file=${arr[0]}
    destination=${arr[1]}
    cp "${_DIR}/../../config/${file}" "${_DIR}/../../tools/${destination:-}/"
  done
  printf "Install finished!\n"
}

_update() {
  for i in "${_PROGRAMS[@]:-}"
  do
    arr=($(echo "$i" | tr ':' "\n"))
    dir=${arr[1]}
    program=${arr[1]}
    printf "Update %s...\n" "${program}"
    git -C "${_DIR}/../../tools/${dir}" pull origin
  done
  printf "Update finished!\n"
}

_delete() {
  _prompt_yn
  for i in "${_PROGRAMS[@]:-}"
  do
    arr=($(echo "$i" | tr ':' "\n"))
    dir=${arr[1]}
    rm -rf ${_DIR}/../../tools/${dir}
  done
  printf "Tools deleted!\n"
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

  if ! [ -x "$(command -v git)" ]; then
    die 'git is required for this script.'
  fi

  if [[ "${1:-}" =~ ^install$ ]]
  then
    _install
  elif [[ "${1:-}" =~ ^delete$ ]]
  then
    _delete
  elif [[ "${1:-}" =~ ^update$ ]]
  then
    _update
  else
    _print_help
  fi
}

# Call `_main` after everything has been defined.
_main "$@"
