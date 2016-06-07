# Stop using Drush with this container.
# . scripts/end-drush.sh

if [[ "$(basename -- "$0")" == "drush-end.sh" ]]; then
  echo "Don't run $0, source it." >&2
  exit 1
fi

PS1="${DK_TMP_PS1}"
unset DK_USER
unset DK_CONTAINER
unset DK_DRUPAL_ROOT
unset DK_TMP_PS1
unalias drush
echo "Drush alias restored, bye!"
