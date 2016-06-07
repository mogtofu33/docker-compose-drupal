#! /bin/bash
# Pull/Update all my images for this project.

docker images | awk '(NR>1) && ($2!~/none/) && ($1 ~ /^mogtofu33/) {print $1":"$2}' | xargs -L1 docker pull
