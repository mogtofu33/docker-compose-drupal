# Drupal 8 Docker Development

## Require

* Docker engine 1.13+: https://docs.docker.com/engine/installation/
* Docker compose 1.15+: https://docs.docker.com/compose/install/

## Introduction

Focus on simple set-up, based on Docker official images and lightweight Alpine Linux to ease maintenance.

### Include
_Every service is optional as declared in the yml file._
* Apache with Php 7 and Xdebug
* MySQL/MariaDB
* PostgreSQL
* [Memcache](https://hub.docker.com/_/memcached)
* [Redis](https://redis.io/)
* [Mailhog](https://github.com/mailhog/MailHog)
* [Solr](http://lucene.apache.org/solr)
* [OpenLdap](https://www.openldap.org)
* [Varnish](https://varnish-cache.org)

### Optional Php Tools
* [Adminer](https://www.adminer.org) (Database management)

## Quick launch new Drupal 8 project

<pre>
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
</pre>

Note: If you have a permission denied from now it's because of owner of <code>/var/run/docker.sock</code>, run docker and docker-compose commands as sudo.

### Access the stack dashboard and your Drupal root

<pre>
http://localhost
</pre>
<pre>
http://localhost:8181
</pre>

If you have copy an existing Drupal project, you can import the database from the adminer link in the dashboard.

### Setup Drupal 8 with Composer

#### Code download

Setup a new Drupal 8 based on a composer template (yes it's slower, but this is the good way!) with user Apache.

Based on [Drupal 8 template](https://github.com/drupal-composer/drupal-project), include [Drush](http://www.drush.org) and [Drupal console](https://drupalconsole.com/), using [Composer](https://getcomposer.org) in the docker service:

<pre>
docker exec -it -u apache dcd-php \
composer create-project drupal-composer/drupal-project:8.x-dev /var/www/localhost/drupal --stability dev --no-interaction
</pre>

_OR_ locally if you have [Composer](https://getcomposer.org/download/), from this project root:
<pre>
composer create-project drupal-composer/drupal-project:8.x-dev data/www/drupal --stability dev --no-interaction
</pre>

#### Install Drupal 8

To use PostGresSQL change _mysql_ to _pgsql_

<pre>
docker exec -it -u apache dcd-php /var/www/localhost/drupal/vendor/bin/drush -y si \
--root=/var/www/localhost/drupal/web \
--account-name=admin \
--account-pass=password \
--db-url=mysql://drupal:drupal@mysql/drupal
</pre>

#### Access your Drupal 8

<pre>
http://localhost
# Login with admin / password
http://localhost/user/login
</pre>

#### Daily usage, add some modules

<pre>
docker exec -it -u apache ddd-apache \
composer -d=/var/www/localhost/drupal require \
drupal/admin_toolbar drupal/ctools drupal/pathauto drupal/token drupal/panels
</pre>

#### Daily usage, enable some modules

<pre>
docker exec -it -u apache ddd-apache \
/var/www/localhost/drupal/vendor/bin/drush -y en \
--root=/var/www/localhost/drupal/web \
admin_toolbar ctools ctools_block ctools_views panels token pathauto
</pre>

#### Daily usage, run a command on the server

<pre>
docker exec -it -u apache ddd-apache \
ls -lah /var/www/localhost/drupal
</pre>

#### Login in the Apache to run commands
<pre>
docker exec -it -u apache ddd-apache bash
</pre>

## Reset the stack

### Destroy containers (data/ is persistent, so you are not loosing db or files)
<pre>docker-compose stop && docker-compose down</pre>

### Remove your persistent data (and lost everything!)
<pre>rm -rf data</pre>

## Suggested tools

* [Opcache GUI](https://github.com/amnuts/opcache-gui)
* [Pimp my Log](http://pimpmylog.com/)
* [Phpmemcacheadmin](https://github.com/wp-cloud/phpmemcacheadmin)
* [Xdebug GUI](https://github.com/splitbrain/xdebug-trace-tree)
* [Adminer extended](https://github.com/dg/adminer-custom)
* [Php Redis Admin](https://github.com/ErikDubbelboer/phpRedisAdmin)

You can find a script in scripts/get-tools.sh folder to download or update all tools.
<pre>
cd THIS_PROJECT/scripts/
chmod +x get-tools.sh
./get-tools.sh
</pre>
