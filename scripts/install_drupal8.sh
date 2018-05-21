#!/usr/bin/env bash
# ____   ____   ____                         _
# |  _ \ / ___| |  _ \ _ __ _   _ _ __   __ _| |
# | | | | |     | | | | '__| | | | '_ \ / _  | |
# | |_| | |___  | |_| | |  | |_| | |_) | (_| | |
# |____/ \____| |____/|_|   \__,_| .__/ \__,_|_|
#                               |_|
#
# Install and prepare a Drupal 8 project.
# https://github.com/Mogtofu33/docker-compose-drupal
#
# Usage:
#   install_drupal8.sh
#
# Depends on:
#  composer docker
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

Install and prepare a Drupal 8 project with Drupal template.
https://github.com/drupal-composer/drupal-project

Usage:
  ${_ME} [install | get-only | install-only]

Options:
  -h --help  Show this screen.
HEREDOC
}

###############################################################################
# Program Functions
###############################################################################

_get_drupal() {
  # Setup Drupal 8 composer project.
  $_COMPOSER create-project drupal-composer/drupal-project:8.x-dev "${DRUPAL_CONTAINER_ROOT}" --stability dev --no-interaction
  $_COMPOSER --working-dir="${DRUPAL_CONTAINER_ROOT}" require "drupal/devel" "drupal/admin_toolbar"
}

_install_drupal() {
  #docker exec -t $PROJECT_CONTAINER_NAME chown -R apache: /www
  $_DOCKER exec -t --user apache "${PROJECT_CONTAINER_NAME}" "${DRUSH_BIN}" "${PROJECT_CONTAINER_ROOT}" -y site:install "${DRUSH_OPTIONS}" >> "${DRUPAL_CONTAINER_ROOT}/drupal-install.log"
  $_DOCKER exec -t --user apache "${PROJECT_CONTAINER_NAME}" "${DRUSH_BIN}" "${PROJECT_CONTAINER_ROOT}" -y pm:enable admin_toolbar >> /dev/null
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

  _check_dependencies_docker
  _check_dependencies_composer
  _check_dependencies_docker_up

  # Run actions.
  if [[ "${1:-}" =~ ^install$ ]]
  then
    _get_drupal
    _install_drupal
  elif [[ "${1:-}" =~ ^get-only$ ]]
  then
    _get_drupal
  elif [[ "${1:-}" =~ ^install-only$ ]]
  then
    _install_drupal
  else
    _print_help
  fi
}

# Call `_main` after everything has been defined.
_main "$@"
