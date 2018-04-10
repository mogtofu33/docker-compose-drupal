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

# Short form: set -u
set -o nounset

# Exit immediately if a pipeline returns non-zero.
set -o errexit

# Print a helpful message if a pipeline with non-zero exit code causes the
# script to exit as described above.
trap 'echo "Aborting due to errexit on line $LINENO. Exit code: $?" >&2' ERR

# Allow the above trap be inherited by all functions in the script.
# Short form: set -E
set -o errtrace

# Return value of a pipeline is the value of the last (rightmost) command to
# exit with a non-zero status, or zero if all commands in the pipeline exit
# successfully.
set -o pipefail

# Set IFS to just newline and tab at the start
SAFER_IFS=$'\n\t'
IFS="${SAFER_IFS}"

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
# Program Functions
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

_install() {
  printf "Install started, clone projects...\n"
  if [ ! -d "${_BASE_PATH}tools" ]; then
    mkdir -p "${_BASE_PATH}tools"
  fi
  for i in "${_PROGRAMS[@]:-}"
  do
    arr=($(echo $i | tr ':' "\n"))
    repo=${arr[0]}
    program=${arr[1]}
    if [ ! -d "${_BASE_PATH}tools/${program}" ]
    then
    	git clone https://github.com/${repo:-} ${_BASE_PATH}tools/${program:-}
    else
      printf "Program already installed, you should run update ?: %s\n" "${program}"
    fi
  done
  for i in "${_CONFIG[@]:-}"
  do
    arr=($(echo $i | tr ':' "\n"))
    file=${arr[0]}
    destination=${arr[1]}
    cp ${_BASE_PATH}config/${file} ${_BASE_PATH}tools/${destination:-}/
  done
  printf "Install finished!\n"
}

_update() {
  for i in "${_PROGRAMS[@]:-}"
  do
    arr=($(echo $i | tr ':' "\n"))
    dir=${arr[1]}
    program=${arr[1]}
    printf "Update ${program}...\n"
    git -C "${_BASE_PATH}tools/${dir}" pull origin
  done
  printf "Update finished!\n"
}

_delete() {
  for i in "${_PROGRAMS[@]:-}"
  do
    arr=($(echo $i | tr ':' "\n"))
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

  if ! [ -x "$(command -v git)" ]; then
    die "Git is not installed. Please install to use this script.\n"
  fi

  # Check where this script is run to fix base path.
  if [[ "${_SOURCE}" = ./${_ME} ]]
  then
    _BASE_PATH="./../"
  elif [[ "${_SOURCE}" = scripts/${_ME} ]]
  then
    _BASE_PATH="./"
  elif [[ "${_SOURCE}" = ./scripts/${_ME} ]]
  then
    _BASE_PATH="./"
  else
    die "This script must be run within DCD project. Invalid command : $0"
  fi

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
