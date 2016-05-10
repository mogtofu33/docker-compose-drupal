#Important must run with ". "! 
#. scripts/drush-end.sh
PS1="${PS1/ \[$CONTAINER\] /}"
unset CONTAINER
unset ALIAS
unalias drush
