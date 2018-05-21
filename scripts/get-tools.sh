#!/usr/bin/env bash
# ____   ____   ____                         _
# |  _ \ / ___| |  _ \ _ __ _   _ _ __   __ _| |
# | | | | |     | | | | '__| | | | '_ \ / _  | |
# | |_| | |___  | |_| | |  | |_| | |_) | (_| | |
# |____/ \____| |____/|_|   \__,_| .__/ \__,_|_|
#                               |_|
#
# Helper to get third party tools, part of Docker Compose Drupal project.
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

source ./helpers/common.sh

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
  ____   ____   ____                         _
 |  _ \ / ___| |  _ \ _ __ _   _ _ __   __ _| |
 | | | | |     | | | | '__| | | | '_ \ / _  | |
 | |_| | |___  | |_| | |  | |_| | |_) | (_| | |
 |____/ \____| |____/|_|   \__,_| .__/ \__,_|_|
                                |_|

Helper to get third party tools, part of Docker Compose Drupal project.

Usage:
  ${_ME} [install | update | delete]
  ${_ME} -h | --help

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
  "memcache/Memcache.php:PhpMemcachedAdmin"
  "redis/config.inc.php:phpRedisAdmin"
)

###############################################################################
# Program Functions
###############################################################################

_install() {
  printf "Install started, clone projects...\n"
  if [ ! -d "${_BASE_PATH}tools" ]; then
    mkdir -p "${_BASE_PATH}tools"
  fi
  for i in "${_PROGRAMS[@]:-}"
  do
    arr=($(echo "$i" | tr ':' "\n"))
    repo=${arr[0]}
    program=${arr[1]}
    if [ ! -d "${_BASE_PATH}tools/${program}" ]
    then
    	git clone "https://github.com/${repo:-}" "${_BASE_PATH}tools/${program:-}"
    else
      printf "Program already installed, you should run update ?: %s\n" "${program}"
    fi
  done
  for i in "${_CONFIG[@]:-}"
  do
    arr=($(echo "$i" | tr ':' "\n"))
    file=${arr[0]}
    destination=${arr[1]}
    cp "${_BASE_PATH}config/${file}" "${_BASE_PATH}tools/${destination:-}/"
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
    git -C "${_BASE_PATH}tools/${dir}" pull origin
  done
  printf "Update finished!\n"
}

_delete() {
  for i in "${_PROGRAMS[@]:-}"
  do
    arr=($(echo "$i" | tr ':' "\n"))
    dir=${arr[1]}
    echo "rm -rf ${_BASE_PATH}tools/${dir}"
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

  _check_dependencies_git

  # Run actions.
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
