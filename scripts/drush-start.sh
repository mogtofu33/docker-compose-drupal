# Run with source with arguments to use Drush with this container.
# . scripts/drush-start.sh apache apache drupaldockercompose_apache_1
export DK_USER=$1
export CONTAINER=$2
export TMP_PS1=$PS1
alias drush="docker exec -u $DK_USER -it $CONTAINER drush --root=/www/drupal"
PS1="$PS1 \[\e[1;31m\][$CONTAINER] \[\e[m\]"
