#!/usr/bin/env bash
#
# Helper to get third party tools, part of Docker compose Drupal project.
#
# Bash Boilerplate: https://github.com/alphabetum/bash-boilerplate
# Bash Boilerplate: Copyright (c) 2015 William Melody • hi@williammelody.com

if [ -z ${STACK_ROOT} ]; then
  _SOURCE="${BASH_SOURCE[0]}"
  while [ -h "$_SOURCE" ]; do
    _DIR="$( cd -P "$( dirname "$_SOURCE" )" && pwd )"
    _SOURCE="$(readlink "$_SOURCE")"
    [[ $_SOURCE != /* ]] && _SOURCE="$_DIR/$_SOURCE"
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
# Print the __program help information.
_print_help() {
  _help_logo
  cat <<HEREDOC
Helper to get third party tools, part of Docker compose Drupal project.

Usage:
  ${_ME} [install | update | delete]

HEREDOC
}

# Initialize __program option variables.
__cmd="${1:-"print_help"}"

###############################################################################
# Variables
###############################################################################

__TOOLS_REPOS=(
  "wp-cloud/phpmemcacheadmin.git:PhpMemcachedAdmin"
  "amnuts/opcache-gui.git:Opcache-gui"
  "splitbrain/xdebug-trace-tree.git:Xdebug-trace"
  "dg/adminer-custom.git:adminerExtended"
  "ErikDubbelboer/phpRedisAdmin.git:phpRedisAdmin"
  "nrk/predis.git:phpRedisAdmin/vendor"
)
__TOOLS_CONFIG=(
  "memcache/Memcache.php:PhpMemcachedAdmin/Config"
  "redis/config.inc.php:phpRedisAdmin/includes"
)

###############################################################################
# Program Functions
###############################################################################

_install() {
  printf "[info] Install started, clone projects...\n"
  if [ ! -d "${STACK_ROOT}/tools" ]; then
    mkdir -p "${STACK_ROOT}/tools"
  fi
  for i in "${__TOOLS_REPOS[@]:-}"
  do
    __arr=($(echo "$i" | tr ':' "\n"))
    __repo=${__arr[0]}
    __program=${__arr[1]}
    if [ ! -d "${STACK_ROOT}/tools/${__program}" ]
    then
      git clone "https://github.com/${__repo:-}" "${STACK_ROOT}/tools/${__program:-}"
    else
      printf "[notice] Program already installed, you should run update ?: %s\n" "${__program}"
    fi
  done

  for i in "${__TOOLS_CONFIG[@]:-}"
  do
    __arr=($(echo "$i" | tr ':' "\n"))
    __file=${__arr[0]}
    __destination=${__arr[1]}
    if [ -f "${STACK_ROOT}/config/${__file}" ]; then
      cp "${STACK_ROOT}/config/${__file}" "${STACK_ROOT}/tools/${__destination}/"
    else
      printf "[notice] Missing config file: %s\n" "config/${__file}"
    fi
  done

  printf "[info] Install finished!\n"
}

_update() {
  for i in "${__TOOLS_REPOS[@]:-}"
  do
    __arr=($(echo "$i" | tr ':' "\n"))
    __dir=${__arr[1]}
    __program=${__arr[1]}
    printf "Update %s...\n" "${__program}"
    git -C "${STACK_ROOT}/tools/${__dir}" pull origin
  done
  printf "[info] Update finished!\n"
}

_delete() {
  _prompt_yn
  for i in "${__TOOLS_REPOS[@]:-}"
  do
    __arr=($(echo "$i" | tr ':' "\n"))
    __dir=${__arr[1]}
    rm -rf ${STACK_ROOT}/tools/${__dir}
  done
  printf "[info] Tools deleted!\n"
}

_test() {
  _install
  _update
  #_delete
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

  # Run command if exist.
  __call="_${__cmd}"
  if [ "$(type -t "${__call}")" == 'function' ]; then
    $__call "@"
  else
    printf "[ERROR] Unknown command: %s\\n" "${__cmd}"
  fi
}

# Call `_main` after everything has been defined.
_main "$@"
