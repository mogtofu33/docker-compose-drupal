# Run with source with arguments to use Drush with this container.
# . scripts/drush-start.sh apache:www-data drupaldockercompose_apache_1

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
 Arguments:
  first argument                 Container name from docker-compose ps
  second argument (optional)     Container user and group, defaultapache:www-data
  third argument (optional)      Drupal folder on container, default /www/drupal
 Options:
  -h,  --help         Display this help and exit

Usage: . drush-start.sh apache:www-data dockercomposedrupal_apache_1

Source . drush-end.sh to stop this Drush session.
HELP
else
  if [ -z "$1" ]; then
    # Get first apache/nginx container running.
    WEB_RUNNING=$(docker-compose ps | grep "apache\|phpfpm" | grep "Up" | cut -d' ' -f 1 | head -1 2> /dev/null)
    if [ $? -eq 1 ]; then
      echo "${RED}[error] No running Apache or Nginx/PhpFpm container found in this folder.${NC}"
      container='';
    else
      container=$WEB_RUNNING
    fi
  else
    container=$1
  fi

  if [[ !$2 ]]; then
    # Detect if we are on apache or nginx.
    if [[ $container == *"apache"* ]]
    then
      user="apache:www-data"
    else
      user="nginx:www-data"
    fi
  else
    user=$2
  fi

  if [[ !$3 ]]; then
    drupal_root='/www/drupal'
  else
    drupal_root=$3
  fi

  # Check if this container exist.
  RUNNING=$(docker inspect --format="{{ .State.Running }}" $container 2> /dev/null)
  if [ $? -eq 1 ]; then
    echo -e "${RED}[error] container $container does not exist, here is all running web containers:${NC}"
    echo "$(docker-compose ps | grep "apache\|phpfpm" | grep 'Up' | cut -d' ' -f 1)"
  else
    export DK_USER=$user
    export DK_CONTAINER=$container
    export DK_DRUPAL_ROOT=$drupal_root
    export DK_TMP_PS1=$PS1

    alias drush="docker exec -u $DK_USER -it $DK_CONTAINER drush --root=$DK_DRUPAL_ROOT"
    PS1="$PS1\[${RED_BOLD}[$DK_CONTAINER]> ${NC}"
  fi

fi
