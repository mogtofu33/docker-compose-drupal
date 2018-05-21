#!/usr/bin/env bash
# ____   ____   ____                         _
# |  _ \ / ___| |  _ \ _ __ _   _ _ __   __ _| |
# | | | | |     | | | | '__| | | | '_ \ / _  | |
# | |_| | |___  | |_| | |  | |_| | |_) | (_| | |
# |____/ \____| |____/|_|   \__,_| .__/ \__,_|_|
#                               |_|
#
# Helper to run postgres dump/restore, part of Docker Compose Drupal project.
# Based on Bash simple Boilerplate.
# https://github.com/Mogtofu33/docker-compose-drupal
#
# Usage:
#   pgsql dump | restore
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

Helper to dump and restore PGSQL db with pg_dump and pg_restore.

Usage:
  ${_ME} [dump | restore]
  ${_ME} -h | --help

Options:
  -h --help  Show this screen.
HEREDOC
}

###############################################################################
# Program Functions
###############################################################################

_dump() {
  docker exec -t "${PROJECT_CONTAINER_PGSQL}" mkdir -p /dump
  docker exec -t "${PROJECT_CONTAINER_PGSQL}" chown -R "$_POSTGRES_ID" /dump

  # If we have an existing dump.
  rm -f ${PROJECT_PGSQL_DUMP_FOLDER}/dump_${_NOW}.pg_dump

  docker exec \
    -t \
    --user "${_USER}" \
    "${PROJECT_CONTAINER_PGSQL}" \
      pg_dump -d "${POSTGRES_DB}" -U "${POSTGRES_USER}" -hlocalhost -Fc -c -b -v -f /dump/dump_${_NOW}.pg_dump \
      --exclude-table-data '*.cache*' --exclude-table-data '*.cachetags*' \
      --exclude-table-data '*.watchdog*' --exclude-table-data '*.node_access*' \
      --exclude-table-data '*.search_api_db_*' --exclude-table-data '*.sessions*' \
      --exclude-table-data '*.sessions*' --exclude-table-data '*.webprofiler*'

  docker cp "${PROJECT_CONTAINER_PGSQL}:/dump/dump_${_NOW}.pg_dump" "${PROJECT_PGSQL_DUMP_FOLDER}/dump_${_NOW}.pg_dump" 
}

_restore() {

  docker exec -t "${PROJECT_CONTAINER_PGSQL}" mkdir -p /dump
  docker exec -t "${PROJECT_CONTAINER_PGSQL}" chown -R "${_POSTGRES_ID}" /dump
  docker cp  "${PROJECT_PGSQL_DUMP_FOLDER}/dump.pg_dump" "${PROJECT_CONTAINER_PGSQL}:/dump/dump.pg_dump"

  docker exec \
    -t \
    --user "${_USER}" \
      createdb -e --owner="${POSTGRES_USER}" "${POSTGRES_DB}"
  docker exec \
    -t \
    --user "${_USER}" \
      psql -e -d ${POSTGRES_DB} -c "GRANT ALL ON database ${POSTGRES_DB} TO ${POSTGRES_USER}"
  docker exec \
    -t \
    --user "${_USER}" \
      pg_restore -h localhost -p 5432 --no-owner --role="${POSTGRES_USER}" -U "${POSTGRES_USER}" -d "${POSTGRES_DB}" -v /dump/dump.pg_dump
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

  # Run actions.
  if [[ "${1:-}" =~ ^dump$ ]]
  then
    _dump
  elif [[ "${1:-}" =~ ^restore$ ]]
  then
    _restore
  else
    _print_help
  fi
}

# Call `_main` after everything has been defined.
_main "$@"

