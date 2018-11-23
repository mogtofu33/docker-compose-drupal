# Drupal 8 Docker Compose Development

[![pipeline status](https://gitlab.com/mog33/docker-compose-drupal/badges/master/pipeline.svg)](https://gitlab.com/mog33/docker-compose-drupal/commits/master)

## Require

* [Docker engine 18+](https://docs.docker.com/install)
* [Docker compose 1.23+](https://docs.docker.com/compose/install)

**Full** Linux support. Tested daily on Ubuntu 16/18.

Windows support is **very, very limited** due to Docker for Windows permissions problems and no privileged support :(

Mac support is **very limited** due to the fact that I don't have a Mac!

## Introduction

Based mostly on Docker official images and lightweight Alpine Linux to ease maintenance.

The purpose is to give flexibility in managment, try to rely as much as possible on offcial tools to avoid any new custom patterns.
If you have to learn the meta tool instead of the tool, then it's not a good one...
This stack is not a one line command but more for users with a good dev-op level and knowledge on each technology used.

See other great project for a Docker based development:

* [Lando](https://docs.devwithlando.io/tutorials/drupal8.html)
* [Docksal](https://docksal.io/)
* [ddev](https://github.com/drud/ddev)
* [docker4drupal](https://github.com/wodby/docker4drupal)

### Include

_Every service is optional as declared in the yml file._

* Apache
* Nginx
* Php 7.1/7.2 fpm with Xdebug
* MySQL/MariaDB
* PostgreSQL
* [Memcache](https://hub.docker.com/_/memcached)
* [Redis](https://redis.io/)
* [Mailhog](https://github.com/mailhog/MailHog)
* [Solr](http://lucene.apache.org/solr)
* [Portainer](https://github.com/portainer/portainer)

### Database management

* [Adminer](https://www.adminer.org)

## Quick launch new Drupal 8 project

### Get this project

```bash
curl -fSL https://gitlab.com/mog33/docker-compose-drupal/-/archive/master/docker-compose-drupal-master.tar.gz -o docker-compose-drupal-master.tar.gz
tar -xzf docker-compose-drupal-master.tar.gz
mv docker-compose-drupal-master docker-compose-drupal
cd docker-compose-drupal
```

### Create your docker compose file from template

```bash
cp docker-compose.tpl.yml docker-compose.yml
```

### Prepare the stack

Choose a database, remove or add services, add your composer cache folder if needed.
Do not touch for a default quick stack.

```bash
vi docker-compose.yml
```

### Create your config file from template

```bash
cp default.env .env
```

### Edit your configuration if needed

Recommended on Unix add your local uid/gid.

```bash
vi .env
```

### Check the yml file and fix if there is an error message

```bash
docker-compose config
```

### Existing Drupal project

For an existing Drupal 8 project, create folders and copy it in _data/www_
Note that based on Composer template web root must be under _drupal/web_
folder. If not you need to adapt Apache vhost config from
_config/apache/vhost.conf_

```bash
mkdir -p data/www/drupal
cp -r _YOUR_DRUPAL_ data/www/drupal/
```

For MySQL, copy your database dump uncompressed in _./data/dump/*.sql_, it
will be automatically imported on the first run.

### Launch the containers

```bash
docker-compose up --build -d
```

### Quick check logs to ensure startup is finished, mostly Apache

```bash
docker-compose logs apache
```

### Access the minimal dashboard

* [http://localhost:8181](http://localhost:8181)

If you have copy an existing Drupal project, you can import the database from the adminer link in the dashboard.

### Setup Vanilla Drupal 8 with Composer

#### Code download

Setup a new Drupal 8 based on a composer template (yes it's slower, but this is the good way!) with user Apache.

Based on [Drupal 8 template](https://github.com/drupal-composer/drupal-project), include [Drush](http://www.drush.org) and [Drupal console](https://drupalconsole.com/), using [Composer](https://getcomposer.org) in the docker service:

```bash
docker exec -it -u apache dcd-php \
    composer create-project drupal-composer/drupal-project:8.x-dev \
    /var/www/localhost/drupal --stability dev --no-interaction
```

_OR_ locally if you have [Composer](https://getcomposer.org/download) installed, from this project root:

```bash
composer create-project drupal-composer/drupal-project:8.x-dev data/www/drupal --stability dev --no-interaction
```

#### Option 1: Install Drupal 8

To use **PostGreSQL** change **mysql** to **pgsql**

You can replace **standard** by an other profile as **minimal** or **demo_umami** for [Drupal 8.6+](https://www.drupal.org/project/demo_umami).

```bash
docker exec -it -u apache dcd-php /var/www/localhost/drupal/vendor/bin/drush -y si standard \
    --root=/var/www/localhost/drupal/web \
    --account-name=admin \
    --account-pass=password \
    --db-url=mysql://drupal:drupal@mysql/drupal
    #--db-url=pgsql://drupal:drupal@pgsql/drupal
```

#### Option 2: Install a Drupal 8 advanced template

See my other project based on drupal_project with more advanced integration but not a distribution (mean you don't need to rely on the distribution maintainers).

* [Drupal Composer advanced template](https://gitlab.com/mog33/drupal-composer-advanced-template)

Assuming we use composer from docker:

```bash
# Step 1: Grab code
curl -fSL https://gitlab.com/mog33/drupal-composer-advanced-template/-/archive/8.x-dev/drupal-composer-advanced-template-8.x-dev.tar.gz -o drupal.tar.gz
tar -xzf drupal.tar.gz
mv drupal-composer-advanced-template-8.x-dev data/www/drupal
# Step 2: Install
docker exec -it -u apache dcd-php /var/www/localhost/drupal/vendor/bin/drush -y si config_installer \
    config_installer_sync_configure_form.sync_directory="../config/sync" \
    --root=/var/www/localhost/drupal/web \
    --account-name=admin \
    --account-pass=password \
    --db-url=mysql://drupal:drupal@mysql/drupal
```

#### Option 3: Install a Drupal 8 Distribution

Drupal provide some usefull [distributions](https://www.drupal.org/project/project_distribution?f%5B2%5D=drupal_core%3A7234) to help you start with a more complete Drupal 8 out of the box.

Here is a non exhaustive list based on top 4, assuming we use composer from docker:

* [Lightning](https://www.drupal.org/project/lightning)

```bash
# Step 1: Grab code
docker exec -it -u apache dcd-php \
    composer create-project acquia/lightning-project \
    /var/www/localhost/drupal --no-interaction
# Step 2: Install
docker exec -it -u apache dcd-php /var/www/localhost/drupal/vendor/bin/drush -y si lightning \
    --root=/var/www/localhost/drupal/web \
    --account-name=admin \
    --account-pass=password \
    --db-url=mysql://drupal:drupal@mysql/drupal
```

* [Thunder](https://www.drupal.org/project/thunder)

```bash
# Step 1: Grab code
docker exec -it -u apache dcd-php \
    composer create-project burdamagazinorg/thunder-project \
    /var/www/localhost/drupal --no-interaction
# Step 2: Install
docker exec -it -u apache dcd-php /var/www/localhost/drupal/vendor/bin/drush -y si thunder \
    --root=/var/www/localhost/drupal/web \
    --account-name=admin \
    --account-pass=password \
    --db-url=mysql://drupal:drupal@mysql/drupal
```

* [Open social](https://www.drupal.org/project/social)

```bash
# Step 1: Grab code
docker exec -it -u apache dcd-php \
    composer create-project goalgorilla/social_template:dev-master \
    /var/www/localhost/drupal --no-interaction
# Step 2: Install
docker exec -it -u apache dcd-php /var/www/localhost/drupal/vendor/bin/drush -y si social \
    --root=/var/www/localhost/drupal/web \
    --account-name=admin \
    --account-pass=password \
    --db-url=mysql://drupal:drupal@mysql/drupal
```

* [Varbase](https://www.drupal.org/project/varbase)

```bash
# Step 1: Grab code
docker exec -it -u apache dcd-php \
    composer create-project Vardot/varbase-project:^8.5.0 \
    /var/www/localhost/drupal --no-interaction
# Step 2: Install
docker exec -it -u apache dcd-php /var/www/localhost/drupal/vendor/bin/drush -y si varbase \
    --root=/var/www/localhost/drupal/web \
    --account-name=admin \
    --account-pass=password \
    --db-url=mysql://drupal:drupal@mysql/drupal
```

#### Access your Drupal 8

* [http://localhost](http://localhost)

Login with _admin_ / _password_:

* [http://localhost/user/login](http://localhost/user/login)

#### Daily usage, add some modules

```bash
docker exec -it -u apache dcd-php \
    composer --working-dir=/var/www/localhost/drupal require \
    drupal/admin_toolbar drupal/ctools drupal/pathauto drupal/token drupal/panels
```

#### Enable some modules

```bash
docker exec -it -u apache dcd-php \
    /var/www/localhost/drupal/vendor/bin/drush -y en \
    --root=/var/www/localhost/drupal/web \
    admin_toolbar ctools ctools_block ctools_views panels token pathauto
```

#### Run a command on the server

```bash
docker exec -it -u apache dcd-php \
    ls -lah /var/www/localhost/drupal/web
```

## Reset the stack

### Destroy containers (data/ is persistent, so you are not loosing db or files)

```bash
docker-compose stop && docker-compose down
```

### Remove your persistent data (and lost everything!)

```bash
rm -rf data
```

_OR_ Only the database

```bash
rm -rf data/databases
```

## Ubuntu/Linux helpers

For Ubuntu (16+) or Linux you can find in _scripts/_ multiple helpers to quickly
run some daily commands from root folder, and drush/drupal links at the root.

```bash
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
```

## Suggested tools

* [Opcache GUI](https://github.com/amnuts/opcache-gui)
* [Phpmemcacheadmin](https://github.com/wp-cloud/phpmemcacheadmin)
* [Xdebug GUI](https://github.com/splitbrain/xdebug-trace-tree)
* [Adminer extended](https://github.com/dg/adminer-custom)
* [Php Redis Admin](https://github.com/ErikDubbelboer/phpRedisAdmin)

You can find a script for Linux in scripts/get-tools.sh folder to download or update all tools:

```bash
cd THIS_PROJECT
chmod +x scripts/get-tools.sh
./scripts/get-tools.sh install
```

## Troubleshooting

Windows support very partial, before running docker-compose you must run in Powershell:

```powershell
$Env:COMPOSE_CONVERT_WINDOWS_PATHS=1
```

Some permissions and privileged problems, so my Dashboard can not access docker.sock.

* [This issue](https://github.com/docker/for-win/issues/1829)

## Build and testing (dev only)

```bash
make run-test
```
