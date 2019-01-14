# Drupal 8 Docker Compose Development

[![pipeline status](https://gitlab.com/mog33/docker-compose-drupal/badges/master/pipeline.svg)](https://gitlab.com/mog33/docker-compose-drupal/commits/master)

- [Require](#require)
- [Introduction](#introduction)
- [(Quick) Install with a new Drupal 8 project](#quick-install-with-a-new-drupal-8-project)
- [Reset the stack](#reset-the-stack)
- [Ubuntu/Linux helpers](#ubuntulinux-helpers)
- [Upgrade](#upgrade)
- [Suggested tools](#suggested-tools)
- [Troubleshooting](#troubleshooting)

## Require

- [Docker engine 18+](https://docs.docker.com/install)
- [Docker compose 1.23+](https://docs.docker.com/compose/install)

**Full** Linux support. Tested daily on Ubuntu 16/18.

**Windows** support is **very, very limited** due to Docker for [Windows permissions problems](https://github.com/docker/for-win/issues/1829) and no privileged support :(

**Mac** support is **very limited** due to the fact that I don't have a Mac!

## Introduction

Based mostly on Docker official images and lightweight [Alpine Linux](https://alpinelinux.org/) to ease maintenance.

This stack is meant to be used as a one Drupal 8 project only quick setup and run.

The purpose is to give flexibility in managment, try to rely as much as possible on offcial tools to avoid any new custom patterns.
If you have to learn the meta tool instead of the tool, then it's not a good one...
This stack is not a one line command but more for users with a good dev-op level and knowledge on each technology used.

See other great project for a Docker based development:

- [Lando](https://docs.devwithlando.io/tutorials/drupal8.html)
- [Docksal](https://docksal.io/)
- [ddev](https://github.com/drud/ddev)
- [docker4drupal](https://github.com/wodby/docker4drupal)

### Include

_Every service is optional as declared in the yml file._

- Apache
- Nginx
- Php 7.1/7.2 fpm with Xdebug
- MySQL/MariaDB
- PostgreSQL
- [Memcache](https://hub.docker.com/_/memcached)
- [Redis](https://redis.io/)
- [Mailhog](https://github.com/mailhog/MailHog)
- [Solr](http://lucene.apache.org/solr)
- [Portainer](https://github.com/portainer/portainer)

### Database management

- [Adminer](https://www.adminer.org)

## (Quick) Install with a new Drupal 8 project

### Get this project

```bash
git clone https://gitlab.com/mog33/docker-compose-drupal.git
cd docker-compose-drupal
```

### Create your docker compose file from template

```bash
cp docker-compose.tpl.yml docker-compose.yml
cp default.env .env
```

### (Optional) Edit configuration

Recommended on Unix add your local uid/gid.

```bash
vi .env
```

### (Optional) Customize the stack

Choose a database, remove or add services, add your composer cache folder if needed.
Do not touch for a default quick stack.

```bash
vi docker-compose.yml
```

### Check the yml file and fix if there is an error message

```bash
docker-compose config
```

### Existing Drupal 8 project

#### Import codebase

For an existing Drupal 8 project, copy it here and rename in _drupal_
Note that based on Composer template web root must be under _drupal/web_
folder. If not you need to adapt Apache vhost config from
_config/apache/vhost.conf_

```bash
cp -r _YOUR_DRUPAL_ drupal
```

#### Import database

For **MySQL**, copy your database dump uncompressed in _./database-mysql-init/*.sql_, it
will be automatically imported on the first run of the stack.

**Or** after the containers are up, under _Linux_ you can place your dump in
_./database-dump_ and use helper scripts:

```bash
scripts/mysql import
scripts/pgsql import
```

### Launch the stack

```bash
docker-compose up --build -d
```

### Access the minimal dashboard

- [http://localhost:8181](http://localhost:8181)

You can import the database from the adminer link in the dashboard.

### Setup Vanilla Drupal 8 with Composer

#### Code download

Setup a new Drupal 8 based on a Composer project (yes it's slower, but this is the good way!) with user Apache.

Based on [Drupal 8 template](https://github.com/drupal-composer/drupal-project), include [Drush](http://www.drush.org) and [Drupal console](https://drupalconsole.com/), using [Composer](https://getcomposer.org) in the docker service:

```bash
docker exec -it -u apache dcd-php \
    composer create-project drupal-composer/drupal-project:8.x-dev \
    /var/www/localhost/drupal --stability dev --no-interaction
```

_OR_ locally if you have [Composer](https://getcomposer.org/download) installed, from this project root:

```bash
composer create-project drupal-composer/drupal-project:8.x-dev drupal --stability dev --no-interaction
```

#### Install Drupal 8

To use **PostGreSQL** change **mysql** to **pgsql**

You can replace **standard** by an other profile as **minimal** or **demo_umami** for [Drupal 8.6+](https://www.drupal.org/project/demo_umami).

```bash
docker exec -it -u apache dcd-php /var/www/localhost/drupal/vendor/bin/drush -y site:install standard \
    --root=/var/www/localhost/drupal/web \
    --account-name=admin \
    --account-pass=password \
    --db-url=mysql://drupal:drupal@mysql/drupal
    #--db-url=pgsql://drupal:drupal@pgsql/drupal
```

#### Option 2: Install a Drupal 8 Distribution

Drupal provide some usefull [distributions](https://www.drupal.org/project/project_distribution?f%5B2%5D=drupal_core%3A7234) to help you start with a more complete Drupal 8 out of the box.

Here is an example, assuming we use composer from docker:

- [Lightning](https://www.drupal.org/project/lightning)

```bash
# Step 1: Grab code
docker exec -it -u apache dcd-php \
    composer create-project acquia/lightning-project \
    /var/www/localhost/drupal --no-interaction
# Step 2: Install
docker exec -it -u apache dcd-php /var/www/localhost/drupal/vendor/bin/drush -y site:install lightning \
    --root=/var/www/localhost/drupal/web \
    --account-name=admin \
    --account-pass=password \
    --db-url=mysql://drupal:drupal@mysql/drupal
```

#### Access your Drupal 8

- [http://localhost](http://localhost)

Login with _admin_ / _password_:

- [http://localhost/user/login](http://localhost/user/login)

#### Daily usage, add some modules

```bash
docker exec -it -u apache dcd-php \
    composer --working-dir=/var/www/localhost/drupal require \
    drupal/admin_toolbar drupal/ctools drupal/pathauto drupal/token drupal/panels
```

With _Linux_, you can use included helper script

```bash
scripts/composer require drupal/admin_toolbar drupal/ctools drupal/pathauto drupal/token drupal/panels
```

#### Enable some modules

```bash
docker exec -it -u apache dcd-php \
    /var/www/localhost/drupal/vendor/bin/drush -y en \
    --root=/var/www/localhost/drupal/web \
    admin_toolbar ctools ctools_block ctools_views panels token pathauto
```

With _Linux_, you can use included helper script

```bash
scripts/drush -y en admin_toolbar ctools ctools_block ctools_views panels token pathauto
```

#### Run a command on the server

```bash
docker exec -it -u apache dcd-php \
    ls -lah /var/www/localhost/drupal/web
```

## Reset the stack

### Destroy containers (./drupal/ is persistent but NOT the database files)

Save your database

```bash
scripts/mysql dump
scripts/pgsql dump
```

Stop and remove containers

```bash
docker-compose down
```

### Remove your persistent data (and lost everything!)

```bash
rm -rf data
```

## Ubuntu/Linux helpers

For Ubuntu (16+) or Linux you can find in _scripts/_ multiple helpers to quickly
run some daily commands from root folder, and drush/drupal links at the root.

```bash
# Run drush or drupal within the container
scripts/drush status
scripts/drupal site:status
# Quickly dump/restore/drop your DB
scripts/mysql --help
scripts/pgsql --help
# Run composer as a service without local installation
scripts/composer --help
scripts/composer status
```

(WIP) Install Drupal 8 variant helpers

```bash
scripts/install-drupal.sh
```

## Upgrade

Because this project is mainly focused on a one time usage the best way to
upgrade is to copy your project to a new version of this project.

## Suggested tools

- [Opcache GUI](https://github.com/amnuts/opcache-gui)
- [Phpmemcacheadmin](https://github.com/wp-cloud/phpmemcacheadmin)
- [Xdebug GUI](https://github.com/splitbrain/xdebug-trace-tree)
- [Adminer extended](https://github.com/dg/adminer-custom)
- [Php Redis Admin](https://github.com/ErikDubbelboer/phpRedisAdmin)

You can find a script for Linux in scripts/get-tools.sh folder to download or update all tools:

```bash
cd THIS_PROJECT
chmod +x scripts/get-tools.sh
./scripts/get-tools.sh install
```

## Troubleshooting

### General problem

In case of any problem, first step is to check the configuraion ansd the logs

```bash
docker-compose config
docker-compose logs
```

### Port 80

If you have already a web server running on port __80__ or __443__ on your machine
you must stop it or change __APACHE_HOST_HTTP_PORT__ in __.env__

### Windows

Windows support very partial, before running docker-compose you must run in Powershell:

```powershell
$Env:COMPOSE_CONVERT_WINDOWS_PATHS=1
```

Some permissions and privileged problems:

- [This issue](https://github.com/docker/for-win/issues/1829)
