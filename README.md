# Drupal 8 Docker Development

## Require

* Docker engine 1.13+: https://docs.docker.com/engine/installation/
* Docker compose 1.13+: https://docs.docker.com/compose/install/

## Introduction

Focus on simple set-up, based on Docker official images and lightweight Alpine Linux to ease maintenance.

### Include
_Every service is optional as declared in the yml file._
* Apache with Php 7 and Xdebug
* MySQL/MariaDB
* PostgreSQL
* [Memcache](https://hub.docker.com/_/memcached)
* [Mailhog](https://github.com/mailhog/MailHog)
* [Solr](http://lucene.apache.org/solr)
* [OpenLdap](https://www.openldap.org)
* [Varnish](https://varnish-cache.org)

### Optional Php Tools
* [Adminer](https://www.adminer.org)

## Quick launch new Drupal 8 project

<pre>
# Clone this project.
git clone https://github.com/Mogtofu33/docker-compose-drupal.git docker-drupal
cd docker-drupal

# Create your docker compose file from template.
cp docker-compose.tpl.yml docker-compose.yml

# (Optional) choose a db, remove or add services, add your composer cache folder
vi docker-compose.yml

# Create your config file from template.
cp default.env .env

# (Optional) edit your configuration if needed.
vi .env

# Check the config and fix if needed
docker-compose config

# Launch the containers.
docker-compose build && docker-compose up -d

# Check logs to ensure startup is finished
docker-compose logs
</pre>

### Access the stack dashboard

<pre>
http://localhost:8181
</pre>

### Setup Drupal 8 with Composer

#### Code download

Setup a new Drupal 8 based on a composer template (yes it's slower than with
Drush but this is the good way!)

Based on [Drupal 8 template](https://github.com/drupal-composer/drupal-project), include [Drush](http://www.drush.org) and [Drupal console](https://drupalconsole.com/).

<pre>
docker exec -it -u apache ddd-apache \
composer create-project drupal-composer/drupal-project:8.x-dev /www/drupal --stability dev --no-interaction
</pre>

#### Install Drupal 8

To use PostGresSQL change _mysql_ to _pgsql_

<pre>
docker exec -it -u apache ddd-apache /www/drupal/vendor/bin/drush -y si \
--root=/www/drupal/web \
--account-name=admin \
--account-pass=password \
--db-url=mysql://drupal:drupal@mysql/drupal
</pre>

#### Access your Drupal 8

<pre>
http://localhost
# Login with admin/password
http://localhost/user/login
</pre>

#### Daily usage, add some modules

<pre>
docker exec -it -u apache ddd-apache \
composer -d=/www/drupal require \
drupal/admin_toolbar drupal/ctools drupal/pathauto drupal/token drupal/panels
</pre>

#### Daily usage, enable some modules

<pre>
docker exec -it -u apache ddd-apache \
/www/drupal/vendor/bin/drush -y en \
--root=/www/drupal/web \
admin_toolbar ctools ctools_block ctools_views panels token pathauto
</pre>

#### Daily usage, run a command on the server

<pre>
docker exec -it -u apache ddd-apache \
ls -lah /www/drupal
</pre>

#### Login in the Apache to run commands
<pre>
docker exec -it -u apache ddd-apache bash
</pre>

## Reset the stack

### Destroy containers (loose drupal files!)
<pre>docker-compose stop && docker-compose down</pre>

### Remove your persistent data (and lost everything!)
<pre>sudo rm -rf data/database data/logs data/www/drupal</pre>

## Suggested tools

* [Opcache GUI](https://github.com/amnuts/opcache-gui)
* [Pimp my Log](http://pimpmylog.com/)
* [Phpmemcacheadmin](https://github.com/wp-cloud/phpmemcacheadmin)
* [Xdebug GUI](https://github.com/splitbrain/xdebug-trace-tree)
* [Adminer extended](https://github.com/dg/adminer-custom)
* [Php Redis Admin](https://github.com/ErikDubbelboer/phpRedisAdmin)

You can find a script in scripts/get-tools.sh folder to download or update all tools.
<pre>
cd THIS_PROJECT
chmod +x scripts/get-tools.sh
./scripts/get-tools.sh
</pre>
