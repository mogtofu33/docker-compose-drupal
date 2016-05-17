# Stop using Drush with this container.
# . scripts/drush-end.sh
PS1="${TMP_PS1}"
unset DK_USER
unset DK_GROUP
unset CONTAINER
unalias drush
