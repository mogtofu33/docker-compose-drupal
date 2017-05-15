#!/bin/bash
# Run with source with arguments to use Drush with this container.
# . scripts/start-drush.sh

RED='\033[0;31m'
RED_BOLD='\033[1;31m'
NC='\033[0m'

if [[ "$(basename -- "$0")" == "drush-start.sh" ]]; then
  echo "Don't run $0, source it." >&2
  exit 1
fi

if [ "$1" == "--help" ] || [ "$1" == "-h" ] ; then
cat <<-HELP
Drupal drush in container script, create alias so every drush cmd
will be executed on the Docker container.
 Arguments (optional):
  first argument      Container name from docker-compose ps, default first web container running
  second argument     Container user and group, default apache:www-data
  third argument      Drupal alias, default @d
 Options:
  -h,  --help         Display this help and exit

Usage: . drush-start.sh dockercomposedrupal_apache_1 apache:www-data

Source . drush-end.sh to stop this Drush session.
HELP
else
  if [ -z "$1" ]; then
    # Get first apache container running.
    WEB_RUNNING=$(docker ps -f "name=apache" -f "status=running" -q | head -1 2> /dev/null)
    if [ -z "$WEB_RUNNING" ]; then
      echo -e "${RED}[error] No running Apache container found, do you run docker-compose up -d ?.${NC}"
      container='';
    else
      container=$(docker inspect --format="{{ .Name }}" $WEB_RUNNING)
      container="${container///}"
    fi
  else
    container=$1
  fi

  if [[ !$2 ]]; then
    user="apache:apache"
  else
    user=$2
  fi

  if [[ !$3 ]]; then
    drupal_alias='@d'
  else
    drupal_alias=$3
  fi

  # Check if this container exist.
  RUNNING=$(docker inspect --format="{{ .State.Running }}" $container 2> /dev/null)
  if [ $? -eq 1 ]; then
    echo -e "${RED}[error] Container $container does not exist, here is all running web containers:${NC}"
    echo "$(docker ps -f 'status=running')"
  else
    export DK_USER=$user
    export DK_CONTAINER=$container
    export DK_DRUPAL_ROOT=$drupal_alias
    export DK_TMP_PS1=$PS1

    alias drush="docker exec --user $DK_USER --interactive $DK_CONTAINER drush $DK_DRUPAL_ROOT"
    PS1="$PS1\[${RED_BOLD}[$DK_CONTAINER]> ${NC}"
  fi

fi
