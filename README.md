# Drupal 8 Docker Development

## Require

**Full** Linux support. Tested daily on Ubuntu 16/18.

Windows support is **very, very limited** due to Docker for Windows permissions problems and no privileged support :(

Mac support is **very limited** due to the fact that I don't have a Mac!

* Docker engine 18+: https://docs.docker.com/install
* Docker compose 1.21+: https://docs.docker.com/compose/install

## Introduction

Focus on simple set-up, based on Docker official images and lightweight Alpine Linux to ease maintenance.

### Include
_Every service is optional as declared in the yml file._
* Apache with Php 7/5 fpm and Xdebug
* MySQL/MariaDB
* PostgreSQL
* [Memcache](https://hub.docker.com/_/memcached)
* [Redis](https://redis.io/)
* [Mailhog](https://github.com/mailhog/MailHog)
* [Solr](http://lucene.apache.org/solr)
* [OpenLdap](https://www.openldap.org)
* [Varnish](https://varnish-cache.org)

### Database management
* [Adminer](https://www.adminer.org)

## Quick launch new Drupal 8 project

    # Clone this project.
    git clone https://github.com/Mogtofu33/docker-compose-drupal.git docker-drupal
    cd docker-drupal

    # Create your docker compose file from template.
    cp docker-compose.tpl.yml docker-compose.yml

    # (Optional) choose a db, remove or add services, add your composer cache folder.
    # But you can let it as it for a default quick stack.
    vi docker-compose.yml

    # Create your config file from template.
    cp default.env .env

    # Edit your configuration if needed, recommended on Unix add your local uid/gid.
    vi .env

    # Check the config and fix if needed.
    docker-compose config

    # For an existing Drupal 8 project, create folders and copy it in
    # Note that based on Composer template you we root should be under _drupal/web_
    # folder. If not you need to adapt Apache vhost config from config/apache/vhost.conf
    mkdir -p data/www/drupal
    cp -r _YOUR_DRUPAL_ data/www/drupal/

    # Launch the containers (first time include downloading Docker images).
    docker-compose up --build -d

    # Quick check logs to ensure startup is finished, mostly Apache.
    docker-compose logs apache


Note: If you have a permission denied from now it's because of owner of <code>/var/run/docker.sock</code>, run docker and docker-compose commands as sudo.

### Access the stack dashboard and your Drupal root

    http://localhost

    http://localhost:8181

If you have copy an existing Drupal project, you can import the database from the adminer link in the dashboard.

### Setup Drupal 8 with Composer

#### Code download

Setup a new Drupal 8 based on a composer template (yes it's slower, but this is the good way!) with user Apache.

Based on [Drupal 8 template](https://github.com/drupal-composer/drupal-project), include [Drush](http://www.drush.org) and [Drupal console](https://drupalconsole.com/), using [Composer](https://getcomposer.org) in the docker service:

    docker exec -it -u apache dcd-php \
    composer create-project drupal-composer/drupal-project:8.x-dev /var/www/localhost/drupal --stability dev --no-interaction

_OR_ locally if you have [Composer](https://getcomposer.org/download/), from this project root:

    composer create-project drupal-composer/drupal-project:8.x-dev data/www/drupal --stability dev --no-interaction


#### Install Drupal 8

To use PostGresSQL change _mysql_ to _pgsql_

    docker exec -it -u apache dcd-php /var/www/localhost/drupal/vendor/bin/drush -y si \
    --root=/var/www/localhost/drupal/web \
    --account-name=admin \
    --account-pass=password \
    --db-url=mysql://drupal:drupal@mysql/drupal

#### Access your Drupal 8

    http://localhost
    # Login with admin / password
    http://localhost/user/login

#### Daily usage, add some modules

    docker exec -it -u apache dcd-php \
    composer -d=/var/www/localhost/drupal require \
    drupal/admin_toolbar drupal/ctools drupal/pathauto drupal/token drupal/panels

#### Daily usage, enable some modules

    docker exec -it -u apache dcd-php \
    /var/www/localhost/drupal/vendor/bin/drush -y en \
    --root=/var/www/localhost/drupal/web \
    admin_toolbar ctools ctools_block ctools_views panels token pathauto

#### Daily usage, run a command on the server

    docker exec -it -u apache dcd-php \
    ls -lah /var/www/localhost/drupal

#### Login in the Apache to run commands

    docker exec -it -u apache dcd-php bash

## Reset the stack

### Destroy containers (data/ is persistent, so you are not loosing db or files)

    docker-compose stop && docker-compose down

### Remove your persistent data (and lost everything!)

    rm -rf data

## Suggested tools

* [Opcache GUI](https://github.com/amnuts/opcache-gui)
* [Pimp my Log](http://pimpmylog.com/)
* [Phpmemcacheadmin](https://github.com/wp-cloud/phpmemcacheadmin)
* [Xdebug GUI](https://github.com/splitbrain/xdebug-trace-tree)
* [Adminer extended](https://github.com/dg/adminer-custom)
* [Php Redis Admin](https://github.com/ErikDubbelboer/phpRedisAdmin)

You can find a script in scripts/get-tools.sh folder to download or update all tools.

    cd THIS_PROJECT
    chmod +x scripts/get-tools.sh
    ./get-tools.sh

## Troubleshooting

Windows support very partial, before running docker-compose you must run in Powershell:

    $Env:COMPOSE_CONVERT_WINDOWS_PATHS=1

Some permissions and privileged problems, so my Dashboard can not access docker.sock.

* https://github.com/docker/for-win/issues/1829
