#!/usr/bin/env bash

_SOURCE="${BASH_SOURCE[0]}"
while [ -h "$_SOURCE" ]; do # resolve $_SOURCE until the file is no longer a symlink
  _DIR="$( cd -P "$( dirname "$_SOURCE" )" && pwd )"
  _SOURCE="$(readlink "$_SOURCE")"
  [[ $_SOURCE != /* ]] && _SOURCE="$_DIR/$_SOURCE" # if $_SOURCE was a relative symlink, we need to resolve it relative to the path where the symlink file was located
done
_DIR="$( cd -P "$( dirname "$_SOURCE" )" && pwd )"

source $_DIR/helpers/common.sh

$_DOCKER exec \
  $tty \
  --interactive \
  --user "${PROJECT_CONTAINER_USER}" \
  "${PROJECT_CONTAINER_NAME}" \
  "${DRUPAL_BIN}" "${PROJECT_CONTAINER_ROOT}" "$@"
