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
  ${_ME} [install | enable]
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

_DRUPAL_ROOT=$(echo "$(pwd)${HOST_WEB_ROOT}"/drupal | sed -e 's/\.//g')
_THEME_PATH="${_DRUPAL_ROOT}/web/themes"

###############################################################################
# Program Functions
###############################################################################

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
  docker exec $tty --user apache "${PROJECT_CONTAINER_NAME}" "${DRUSH_BIN}" "${PROJECT_CONTAINER_ROOT}" -y theme:enable bootstrap
  docker exec $tty --user apache "${PROJECT_CONTAINER_NAME}" "${DRUSH_BIN}" "${PROJECT_CONTAINER_ROOT}" -y theme:enable "${_THEME_NAME}"
  docker exec $tty --user apache "${PROJECT_CONTAINER_NAME}" "${DRUSH_BIN}" "${PROJECT_CONTAINER_ROOT}" -y config:set system.theme default "${_THEME_NAME}"

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

  _check_dependencies_composer
  _check_dependencies_compass
  _check_dependencies_docker

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
