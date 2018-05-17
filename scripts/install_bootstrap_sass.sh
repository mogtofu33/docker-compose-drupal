#!/usr/bin/env bash
# ____   ____   ____                         _
# |  _ \ / ___| |  _ \ _ __ _   _ _ __   __ _| |
# | | | | |     | | | | '__| | | | '_ \ / _  | |
# | |_| | |___  | |_| | |  | |_| | |_) | (_| | |
# |____/ \____| |____/|_|   \__,_| .__/ \__,_|_|
#                               |_|
#
# Install and prepare a Drupal 8 Bootsrap Sass sub theme.
# https://github.com/Mogtofu33/docker-compose-drupal
#
# For Sass support on Ubuntu 16.04/18.04 you need
#   ruby-full ruby-compass ruby-sass ruby-bootstrap-sass
#
# Usage:
#   install_bootstrap_sass.sh
#
# Depends on:
#  composer compass docker
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

Install and prepare a Drupal 8 Bootsrap Sass sub theme.
For more details see:
https://drupal-bootstrap.org/api/bootstrap/starterkits%21sass%21README.md/group/sub_theming_sass/8

Usage:
  ${_ME} [install | enable ]
  ${_ME} -h | --help

Options:
  -h --help  Show this screen.
HEREDOC
}

###############################################################################
# Variables
###############################################################################

# Base variables for this script, can be edited.
_THEME_NAME="bootstrap_sass"
_THEME_TITLE="Bootstrap Sass"
_BOOTSTRAP_VERSION="3.3.7"
_CONFIG_RB="https://gist.githubusercontent.com/Mogtofu33/c8bd086d12a6b6540763610893da5364/raw/fcfa4d4a15dbb45b5b6f8fc70f4d0a4bef8081f5/config_dev.rb"

# Check where this script is run to fix base path.
if [[ "${_SOURCE}" = ./${_ME} ]]
then
  die "This script must be run from the ROOT DCD project. Invalid command : ${_SOURCE}"
elif [[ "${_SOURCE}" = scripts/${_ME} ]]
then
    _BASE_PATH="./"
elif [[ "${_SOURCE}" = ./scripts/${_ME} ]]
then
    _BASE_PATH="./"
else
  die "This script must be run within DCD project. Invalid command : ${_SOURCE}"
fi

source ${_BASE_PATH}.env

_DRUPAL_ROOT=$(echo "$(pwd)${HOST_WEB_ROOT}"/drupal | sed -e 's/\.//g')
_THEME_PATH="${_DRUPAL_ROOT}/web/themes"
_PROJECT_CONTAINER_NAME="dcd-php"
_DRUSH_BIN="/var/www/localhost/drupal/vendor/bin/drush"
_DRUSH_ROOT="--root=/var/www/localhost/drupal/web"

###############################################################################
# Program Functions
###############################################################################

_check_dependencies() {

  if ! [ -x "$(command -v composer)" ]; then
    die "Composer is not installed. Please install to use this script.\n"
  fi

  if ! [ -x "$(command -v compass)" ]; then
    die "Compass is not installed. Please install to use this script.\n"
  fi

  if ! [ -x "$(command -v docker)" ]; then
    die "Docker is not installed. Please install to use this script.\n"
  fi

}

_install_bootstrap() {
  # Add Bootstrap theme of Drupal 8 with composer.
  printf ">> [setup::info] Install Bootstrap for Drupal 8.\\n"
  composer --working-dir="${_DRUPAL_ROOT}" require "drupal/bootstrap:^3"
}

_install_bootstrap_subtheme() {
  # Create bootstrap subtheme.
  # see https://drupal-bootstrap.org/api/bootstrap/starterkits%21sass%21README.md/group/sub_theming_sass/8
  printf ">> [setup::info] Create %s subtheme.\\n" "${_THEME_TITLE}"
  mkdir -p "${_THEME_PATH}"/custom
  cp -r "${_THEME_PATH}"/contrib/bootstrap/starterkits/sass/ "${_THEME_PATH}"/custom/"${_THEME_NAME}"

  # Copy and adpat config to get a default block position.
  cp -r "${_THEME_PATH}"/contrib/bootstrap/config/optional/ "${_THEME_PATH}"/custom/"${_THEME_NAME}"/config/
  for i in "${_THEME_PATH}"/custom/"${_THEME_NAME}"/config/optional/*.yml; do
    new_file=$(echo "$i" | sed "s/block\.bootstrap\_/block\.${_THEME_NAME}\_/g");
    mv "$i" "$new_file";
    sed -i -e "s/id: bootstrap_/id: ${_THEME_NAME}_/g" "$new_file";
    sed -i -e "s/theme: bootstrap/theme: ${_THEME_NAME}/g" "$new_file";
    sed -i -e "s/\- bootstrap/\- ${_THEME_NAME}/g" "$new_file";
  done

  # Get Bootstrap sass source.
  wget -q -O "${_THEME_PATH}"/custom/"${_THEME_NAME}"/${_BOOTSTRAP_VERSION}.tar.gz https://github.com/twbs/bootstrap-sass/archive/v${_BOOTSTRAP_VERSION}.tar.gz
  tar -xvzf "${_THEME_PATH}"/custom/"${_THEME_NAME}"/${_BOOTSTRAP_VERSION}.tar.gz -C "${_THEME_PATH}"/custom/"${_THEME_NAME}"/
  mv "${_THEME_PATH}"/custom/"${_THEME_NAME}"/bootstrap-sass-${_BOOTSTRAP_VERSION} "${_THEME_PATH}"/custom/"${_THEME_NAME}"/bootstrap
  rm -f "${_THEME_PATH}"/custom/"${_THEME_NAME}"/${_BOOTSTRAP_VERSION}.tar.gz
  mv "${_THEME_PATH}"/custom/"${_THEME_NAME}"/THEMENAME.starterkit.yml "${_THEME_PATH}"/custom/"${_THEME_NAME}"/"${_THEME_NAME}".info.yml
  mv "${_THEME_PATH}"/custom/"${_THEME_NAME}"/THEMENAME.libraries.yml "${_THEME_PATH}"/custom/"${_THEME_NAME}"/"${_THEME_NAME}".libraries.yml
  mv "${_THEME_PATH}"/custom/"${_THEME_NAME}"/THEMENAME.theme "${_THEME_PATH}"/custom/"${_THEME_NAME}"/"${_THEME_NAME}".theme
  mv "${_THEME_PATH}"/custom/"${_THEME_NAME}"/config/install/THEMENAME.settings.yml "${_THEME_PATH}"/custom/"${_THEME_NAME}"/config/install/"${_THEME_NAME}".settings.yml
  mv "${_THEME_PATH}"/custom/"${_THEME_NAME}"/config/schema/THEMENAME.schema.yml "${_THEME_PATH}"/custom/"${_THEME_NAME}"/config/schema/"${_THEME_NAME}".schema.yml

  # We need a config file for compiling.
  wget -q -O "${_THEME_PATH}"/custom/"${_THEME_NAME}"/config.rb ${_CONFIG_RB}

  # Locally edit files.
  sed -i -e "s/THEMETITLE/${_THEME_TITLE}/g" "${HOST_WEB_ROOT}"/drupal/web/themes/custom/"${_THEME_NAME}"/"${_THEME_NAME}".info.yml
  sed -i -e "s/THEMENAME/${_THEME_NAME}/g" "${HOST_WEB_ROOT}"/drupal/web/themes/custom/"${_THEME_NAME}"/"${_THEME_NAME}".info.yml
  sed -i -e "s/THEMETITLE/${_THEME_TITLE}/g" "${HOST_WEB_ROOT}"/drupal/web/themes/custom/"${_THEME_NAME}"/config/schema/"${_THEME_NAME}".schema.yml
  sed -i -e "s/THEMENAME/${_THEME_NAME}/g" "${HOST_WEB_ROOT}"/drupal/web/themes/custom/"${_THEME_NAME}"/config/schema/"${_THEME_NAME}".schema.yml

  # Compass compile.
  compass compile "${HOST_WEB_ROOT}"/drupal/web/themes/custom/"${_THEME_NAME}"

  printf ">> [setup::info] Bootstrap Sass subtheme installed!\\n"
}

_enable_bootstrap() {
  # Run drush commands to enable this theme with drush bin from previous script (setup_DCD_D8_ubuntu.sh).
  printf "[setup::info] Enable %s subtheme.\\n" "${_THEME_TITLE}"
  docker exec -t --user apache "${_PROJECT_CONTAINER_NAME}" "${_DRUSH_BIN}" "${_DRUSH_ROOT}" -y theme:enable bootstrap
  docker exec -t --user apache "${_PROJECT_CONTAINER_NAME}" "${_DRUSH_BIN}" "${_DRUSH_ROOT}" -y theme:enable "${_THEME_NAME}"
  docker exec -t --user apache "${_PROJECT_CONTAINER_NAME}" "${_DRUSH_BIN}" "${_DRUSH_ROOT}" -y config:set system.theme default "${_THEME_NAME}"

  printf "[setup::info] Bootstrap Sass subtheme enabled!\\n"
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

  _check_dependencies

  # Check where this script is run to fix base path.
  if [[ "${_SOURCE}" = ./${_ME} ]]
  then
    _BASE_PATH="../../"
  elif [[ "${_SOURCE}" = scripts/${_ME} ]]
  then
    _BASE_PATH="../"
  elif [[ "${_SOURCE}" = ./scripts/${_ME} ]]
  then
    _BASE_PATH="../"
  else
    die "This script must be run within DCD project. Invalid command : $0"
  fi

  # Run actions.
  if [[ "${1:-}" =~ ^install$ ]]
  then
    _install_bootstrap
    _install_bootstrap_subtheme
    _enable_bootstrap
  elif [[ "${1:-}" =~ ^enable$ ]]
  then
    _enable_bootstrap
  else
    _print_help
  fi
}

# Call `_main` after everything has been defined.
_main "$@"
