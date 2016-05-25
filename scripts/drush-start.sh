# Run with source with arguments to use Drush with this container.
# . scripts/drush-start.sh apache:www-data drupaldockercompose_apache_1

if [[ "$(basename -- "$0")" == "drush-start.sh" ]]; then
  echo "Don't run $0, source it." >&2
  exit 1
fi

if [ "$1" == "--help" ] || [ "$1" == "-h" ] ; then
cat <<-HELP
Drupal drush in container script, create alias so every drush cmd 
will be executed on the Docker container.
 Arguments:
  first argument               Container user and group as apache:www-data
  second argument              Container name from docker-compose ps
  third argument (optional)    Drupal folder on container, default /www/drupal
 Options:
  -h,  --help         Display this help and exit

Usage: . drush-start.sh apache:www-data dockercomposedrupal_apache_1

Source . drush-end.sh to stop this Drush session.

HELP
else

  if [ -z "$1" ]; then
    echo "[i] Set default user 'apache:www-data', set as first argument to override."
    user="apache:www-data"
  else
    user=$1
  fi

  if [ -z "$2" ]; then
    echo "[i] Set default container name 'dockercomposedrupal_apache_1', set as second argument to override."
    container='dockercomposedrupal_apache_1'
  else
    container=$2
  fi

  if [[ !$3 ]]; then
    drupal_root='/www/drupal'
  else
    drupal_root=$3
  fi

  # Check if this container exist.
  RUNNING=$(docker inspect --format="{{ .State.Running }}" $container 2> /dev/null)
  if [ $? -eq 1 ]; then
    echo "[error] $container does not exist."
  else
    export DK_USER=$user
    export DK_CONTAINER=$container
    export DK_DRUPAL_ROOT=$drupal_root
    export DK_TMP_PS1=$PS1

    alias drush="docker exec -u $DK_USER -it $DK_CONTAINER drush --root=$DK_DRUPAL_ROOT"
    PS1="$PS1\[\e[1;31m\][$DK_CONTAINER]> \[\e[m\]"
  fi

fi
