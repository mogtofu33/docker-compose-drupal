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
  _help_logo
  cat <<HEREDOC
Install and prepare a Drupal 8 Bootsrap Sass sub theme.
For more details see:
https://drupal-bootstrap.org/api/bootstrap/starterkits%21sass%21README.md/group/sub_theming_sass/8

Usage:
  ${_ME} [install | install-existing | enable] [DRUPAL_ROOT_FOLDER]

Options:
  -h --help  Show this screen.

  install:           Composer require, Create subtheme, Enable subtheme
  install-existing:  Create subtheme, Enable subtheme
  enable:            Enable subtheme
HEREDOC
}

###############################################################################
# Variables
###############################################################################

# Base variables for this script, can be edited.
__theme_name="bootstrap_sass"
__theme_title="Bootstrap Sass"
__bootstrap_version="3.3.7"
# __config_rb="https://gist.githubusercontent.com/Mogtofu33/c8bd086d12a6b6540763610893da5364/raw/fcfa4d4a15dbb45b5b6f8fc70f4d0a4bef8081f5/config_dev.rb"
__config_rb="https://gitlab.com/mog33/gitlab-ci-drupal/snippets/1751092/raw"

if [ ${2:-} ]; then
  __drupal_root=${2:-}
else
  if [ "${HOST_WEB_ROOT}" == "" ]; then
    die "Missing env value HOST_WEB_ROOT, set drupal root folder as second argument of this program."
  fi
  __drupal_root=$(echo "$(pwd)${HOST_WEB_ROOT}"/drupal | sed -e 's/\.//g')
fi

__theme_path="${__drupal_root}web/themes"

if [ ! -d "${__theme_path}" ]; then
  die "Cannot access folder" "${__theme_path}"
fi

printf ">> Target path for subtheme is %s\\n" "${__theme_path}"
_prompt_yn

###############################################################################
# Program Functions
###############################################################################

_install_bootstrap() {
  # Add Bootstrap theme of Drupal 8 with composer.
  printf ">> [setup::info] Install Bootstrap for Drupal 8.\\n"
  composer --working-dir="${__drupal_root}" require "drupal/bootstrap:^3"
}

_install_bootstrap_subtheme() {
  # Create bootstrap subtheme.
  # see https://drupal-bootstrap.org/api/bootstrap/starterkits%21sass%21README.md/group/sub_theming_sass/8
  printf ">> [setup::info] Create %s subtheme.\\n" "${__theme_title}"
  mkdir -p "${__theme_path}"/custom
  cp -r "${__theme_path}"/contrib/bootstrap/starterkits/sass/ "${__theme_path}"/custom/"${__theme_name}"

  # Copy and adpat config to get a default block position.
  cp -r "${__theme_path}"/contrib/bootstrap/config/optional/ "${__theme_path}"/custom/"${__theme_name}"/config/
  for i in "${__theme_path}"/custom/"${__theme_name}"/config/optional/*.yml; do
    new_file=$(echo "$i" | sed "s/block\.bootstrap\_/block\.${__theme_name}\_/g");
    mv "$i" "$new_file";
    sed -i -e "s/id: bootstrap_/id: ${__theme_name}_/g" "$new_file";
    sed -i -e "s/theme: bootstrap/theme: ${__theme_name}/g" "$new_file";
    sed -i -e "s/\- bootstrap/\- ${__theme_name}/g" "$new_file";
  done

  # Get Bootstrap sass source.
  wget -q -O "${__theme_path}"/custom/"${__theme_name}"/${__bootstrap_version}.tar.gz https://github.com/twbs/bootstrap-sass/archive/v${__bootstrap_version}.tar.gz
  tar -xvzf "${__theme_path}"/custom/"${__theme_name}"/${__bootstrap_version}.tar.gz -C "${__theme_path}"/custom/"${__theme_name}"/
  mv "${__theme_path}"/custom/"${__theme_name}"/bootstrap-sass-${__bootstrap_version} "${__theme_path}"/custom/"${__theme_name}"/bootstrap
  rm -f "${__theme_path}"/custom/"${__theme_name}"/${__bootstrap_version}.tar.gz
  mv "${__theme_path}"/custom/"${__theme_name}"/THEMENAME.starterkit.yml "${__theme_path}"/custom/"${__theme_name}"/"${__theme_name}".info.yml
  mv "${__theme_path}"/custom/"${__theme_name}"/THEMENAME.libraries.yml "${__theme_path}"/custom/"${__theme_name}"/"${__theme_name}".libraries.yml
  mv "${__theme_path}"/custom/"${__theme_name}"/THEMENAME.theme "${__theme_path}"/custom/"${__theme_name}"/"${__theme_name}".theme
  mv "${__theme_path}"/custom/"${__theme_name}"/config/install/THEMENAME.settings.yml "${__theme_path}"/custom/"${__theme_name}"/config/install/"${__theme_name}".settings.yml
  mv "${__theme_path}"/custom/"${__theme_name}"/config/schema/THEMENAME.schema.yml "${__theme_path}"/custom/"${__theme_name}"/config/schema/"${__theme_name}".schema.yml

  # We need a config file for compiling.
  wget -q -O "${__theme_path}"/custom/"${__theme_name}"/config.rb ${__config_rb}

  # Locally edit files.
  sed -i -e "s/THEMETITLE/${__theme_title}/g" "${HOST_WEB_ROOT}"/drupal/web/themes/custom/"${__theme_name}"/"${__theme_name}".info.yml
  sed -i -e "s/THEMENAME/${__theme_name}/g" "${HOST_WEB_ROOT}"/drupal/web/themes/custom/"${__theme_name}"/"${__theme_name}".info.yml
  sed -i -e "s/THEMETITLE/${__theme_title}/g" "${HOST_WEB_ROOT}"/drupal/web/themes/custom/"${__theme_name}"/config/schema/"${__theme_name}".schema.yml
  sed -i -e "s/THEMENAME/${__theme_name}/g" "${HOST_WEB_ROOT}"/drupal/web/themes/custom/"${__theme_name}"/config/schema/"${__theme_name}".schema.yml

  # Compass compile.
  compass compile "${HOST_WEB_ROOT}"/drupal/web/themes/custom/"${__theme_name}"

  printf ">> [setup::info] Bootstrap Sass subtheme installed!\\n"
}

_enable_bootstrap() {
  # Run drush commands to enable this theme with drush bin from previous script (setup_DCD_D8_ubuntu.sh).
  printf "[setup::info] Enable %s subtheme.\\n" "${__theme_title}"
  docker exec $tty --user "${PROJECT_CONTAINER_USER}" "${PROJECT_CONTAINER_NAME}" "${DRUSH_BIN}" "${PROJECT_CONTAINER_ROOT}" -y theme:enable bootstrap
  docker exec $tty --user "${PROJECT_CONTAINER_USER}" "${PROJECT_CONTAINER_NAME}" "${DRUSH_BIN}" "${PROJECT_CONTAINER_ROOT}" -y theme:enable "${__theme_name}"
  docker exec $tty --user "${PROJECT_CONTAINER_USER}" "${PROJECT_CONTAINER_NAME}" "${DRUSH_BIN}" "${PROJECT_CONTAINER_ROOT}" -y config:set system.theme default "${__theme_name}"

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

  if [[ "${1:-}" =~ ^install$ ]]
  then
    _install_bootstrap
    _install_bootstrap_subtheme
    _enable_bootstrap
  elif [[ "${1:-}" =~ ^install-existing$ ]]
  then
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
