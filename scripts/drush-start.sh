  #Put in a scripts folder in your drupal and run with source
  #Important must run with ". "! 
  #. scripts/drush-start.sh drupal7 drupal
  export CONTAINER=$1
  export ALIAS=$2
  alias drush="docker exec -it $CONTAINER drush @$ALIAS"
  $PS1="$PS1 [$CONTAINER]"
