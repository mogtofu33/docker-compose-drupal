# Drupal 8 Docker Compose Development

## Require

* [Docker engine 18+](https://docs.docker.com/install)
* [Docker compose 1.22+](https://docs.docker.com/compose/install)

**Full** Linux support. Tested daily on Ubuntu 16/18.

Windows support is **very, very limited** due to Docker for Windows permissions problems and no privileged support :(

Mac support is **very limited** due to the fact that I don't have a Mac!

## Introduction

Based mostly on Docker official images and lightweight Alpine Linux to ease maintenance.

The purpose is to give flexibility in managment, try to rely as much as possible on offcial tools to avoid any new custom patterns.
If you have to learn the meta tool instead of the tool, then it's not a good one...

This stack is not a one line command but more for users with a good dev-op level.

See other great project for a Docker based development:

* [Drupal VM](https://www.drupalvm.com)
* [Lando](https://docs.devwithlando.io/tutorials/drupal8.html)
* [Docksal](https://docksal.io/)

### Include

_Every service is optional as declared in the yml file._

* Apache
* Php 7/5 fpm with Xdebug
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

    # Check the yml file and fix if there is an error message.
    docker-compose config

    # For an existing Drupal 8 project, create folders and copy it in data/www
    # Note that based on Composer template web root must be under drupal/web
    # folder. If not you need to adapt Apache vhost config from
    # config/apache/vhost.conf
    mkdir -p data/www/drupal
    cp -r _YOUR_DRUPAL_ data/www/drupal/

    # For MySQL, copy your database dump uncompressed in ./data/dump/*.sql, it
    # will be automatically imported on the first run.

    # Launch the containers (first time include downloading Docker images).
    docker-compose up --build -d

    # Quick check logs to ensure startup is finished, mostly Apache.
    docker-compose logs apache

_Note_: If you have a permission denied from it's probably because of owner of `/var/run/docker.sock`, run docker and docker-compose commands as sudo.

### Access the stack dashboard and your Drupal root

* [http://localhost:8181](http://localhost:8181)
* [http://localhost](http://localhost)

If you have copy an existing Drupal project, you can import the database from the adminer link in the dashboard.

### Setup Drupal 8 with Composer

#### Code download

Setup a new Drupal 8 based on a composer template (yes it's slower, but this is the good way!) with user Apache.

Based on [Drupal 8 template](https://github.com/drupal-composer/drupal-project), include [Drush](http://www.drush.org) and [Drupal console](https://drupalconsole.com/), using [Composer](https://getcomposer.org) in the docker service:

    docker exec -it -u apache dcd-php \
    composer create-project drupal-composer/drupal-project:8.x-dev /var/www/localhost/drupal --stability dev --no-interaction

_OR_ locally if you have [Composer](https://getcomposer.org/download/) installed, from this project root:

    composer create-project drupal-composer/drupal-project:8.x-dev data/www/drupal --stability dev --no-interaction

#### Install Drupal 8

To use PostGreSQL change _mysql_ to _pgsql_

    docker exec -it -u apache dcd-php /var/www/localhost/drupal/vendor/bin/drush -y si \
        --root=/var/www/localhost/drupal/web \
        --account-name=admin \
        --account-pass=password \
        --db-url=mysql://drupal:drupal@mysql/drupal

#### Access your Drupal 8

    http://localhost

Login with _admin_ / _password_:

    http://localhost/user/login

#### Daily usage, add some modules

    docker exec -it -u apache dcd-php \
        composer --working-dir=/var/www/localhost/drupal require \
        drupal/admin_toolbar drupal/ctools drupal/pathauto drupal/token drupal/panels

#### Enable some modules

    docker exec -it -u apache dcd-php \
        /var/www/localhost/drupal/vendor/bin/drush -y en \
        --root=/var/www/localhost/drupal/web \
        admin_toolbar ctools ctools_block ctools_views panels token pathauto

#### Run a command on the server

    docker exec -it -u apache dcd-php \
        ls -lah /var/www/localhost/drupal/web

## Reset the stack

### Destroy containers (data/ is persistent, so you are not loosing db or files)

    docker-compose stop && docker-compose down

### Remove your persistent data (and lost everything!)

    rm -rf data

_OR_ Only the database

    rm -rf data/databases

## Ubuntu/Linux helpers

For Ubuntu (16+) or Linux you can find in _scripts/_ multiple helpers to quickly
run some daily commands from root folder, and drush/drupal links at the root.

    # Run drush or drupal within the container
    ./drush status
    ./drupal site:status
    # Run a bash command in the Php container
    scripts/dcmd ls -lah /var/www/localhost
    # Quickly dump/restore/drop your DB
    scripts/mysql --help
    scripts/pgsql --help
    # Run composer as a service without local installation
    scripts/composer --help
    scripts/composer status

## Suggested tools

* [Opcache GUI](https://github.com/amnuts/opcache-gui)
* [Phpmemcacheadmin](https://github.com/wp-cloud/phpmemcacheadmin)
* [Xdebug GUI](https://github.com/splitbrain/xdebug-trace-tree)
* [Adminer extended](https://github.com/dg/adminer-custom)
* [Php Redis Admin](https://github.com/ErikDubbelboer/phpRedisAdmin)

You can find a script for Linux in scripts/get-tools.sh folder to download or update all tools:

    cd THIS_PROJECT
    chmod +x scripts/get-tools.sh
    ./get-tools.sh

## Troubleshooting

Windows support very partial, before running docker-compose you must run in Powershell:

    $Env:COMPOSE_CONVERT_WINDOWS_PATHS=1

Some permissions and privileged problems, so my Dashboard can not access docker.sock.

* [This issue](https://github.com/docker/for-win/issues/1829)

## Build and testing (dev only)

        make run-test
