#!/bin/bash

# This is an helper to setup this docker compose Drupal stack on Ubuntu 16.04.
# This script must be run as ubuntu user with sudo privileges without password.
# We assume that docker and docker-compose is properly installed when using this
# script (From cloud config files in this folder).
# This script is used with a cloud config setup from this folder.

# Variables.
docker_stack_repo="https://github.com/Mogtofu33/docker-compose-drupal.git"
project_path="$HOME/docker-compose-drupal"
project_container_apache="dockercomposedrupal_apache_1"
project_root="$project_path/data/www"

# Fix permissions.
sudo chown -R ubuntu:ubuntu /home/ubuntu

# Get a Docker compose stack (Apache/Php/Mysql/Mailhog/Solr).
if [ ! -d "$project_path" ]; then
  echo "[setup::info] Clone Docker stack and tools..."
  git clone $docker_stack_repo $project_path
  # set up tools from stack
  cd $project_path;
  ./scripts/get-tools.sh
else
  echo "[setup::info] Docker stack already here!"
fi

# Set-up and launch this Docker compose stack.
echo "[setup::info] Prepare Docker stack and set-up tools..."
cp $project_path/default.env $project_path/.env
# Default file is Apache/Mysql/Memcache/Solr/Mailhog.
cp $project_path/docker-compose.tpl.yml $project_path/docker-compose.yml
cd $project_path
docker-compose up -d

# Check if containers are up...
RUNNING=$(docker inspect --format="{{ .State.Running }}" $project_container_apache 2> /dev/null)
if [ $? -eq 1 ]; then
  echo "[setup::ERROR] Container $project_container_apache does not exist..."
  # Wait a bit for stack to be up....
  sleep 30s
fi

# Add project variables to environment.
cat <<EOT >> /home/ubuntu/.profile
# Basic bashrc call.
if [ -n "$BASH_VERSION" ]; then
    # include .bashrc if it exists
    if [ -f "$HOME/.bashrc" ]; then
        . "$HOME/.bashrc"
    fi
fi
# Docker stack variables.
PROJECT_PATH="$project_path"
PROJECT_ROOT="$project_path/data/www"
PROJECT_CONTAINER_NAME="$project_container_apache"
EOT

# Add cmd in container bin for use with ssh.
sudo touch /usr/local/bin/dcmd
sudo chown ubuntu:ubuntu /usr/local/bin/dcmd
sudo chmod +x /usr/local/bin/dcmd
cat <<EOT > /usr/local/bin/dcmd
#!/bin/bash
docker exec -it --user apache $project_container_apache \$@
EOT

# Convenient links.
ln -s $project_root /home/ubuntu/www
sudo ln -s $project_root /www
sudo chown ubuntu: /www
ln -s $project_path /home/ubuntu/root

echo -e ">>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>\n"
echo -e "[setup::info] Docker compose stack install finished!\n"
echo -e "<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<\n"
