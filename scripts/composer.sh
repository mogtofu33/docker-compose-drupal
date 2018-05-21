#!/usr/bin/env bash
# ____   ____   ____                         _
# |  _ \ / ___| |  _ \ _ __ _   _ _ __   __ _| |
# | | | | |     | | | | '__| | | | '_ \ / _  | |
# | |_| | |___  | |_| | |  | |_| | |_) | (_| | |
# |____/ \____| |____/|_|   \__,_| .__/ \__,_|_|
#                               |_|
#
# Helper to execute Composer as a standalone docker container.
# https://github.com/Mogtofu33/docker-compose-drupal
#
# Usage:
#   composer.sh
#
# Depends on:
#  docker
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

Helper to execute Composer as a standalone docker container, see
https://getcomposer.org/doc/03-cli.md for commands details.
For require command it's recommended to use --ignore-platform-
and --no-scripts options.

Usage:
  ${_ME} [status | require | remove | outdated | ... ]
  ${_ME} -h | --help

Options:
  -h --help  Show this screen.
HEREDOC
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

  # Avoid complex option parsing when only one program option is expected.
  if [[ "${1:-}" =~ ^-h|--help$  ]]
  then
    _print_help
  else
    $_DOCKER run \
      $tty \
      --interactive \
      --rm \
      --user "${LOCAL_UID}":"${LOCAL_GID}" \
      --volume /etc/passwd:/etc/passwd:ro \
      --volume /etc/group:/etc/group:ro \
      --volume "${_DRUPAL_ROOT}":/app \
        composer --working-dir=/app "$@"
  fi

}

# Call `_main` after everything has been defined.
_main "$@"
