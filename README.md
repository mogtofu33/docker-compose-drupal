# Drupal 8 Docker Development

## Require

* Docker engine 1.13+: https://docs.docker.com/engine/installation/
* Docker compose 1.13+: https://docs.docker.com/compose/install/

## Introduction

Focus on simple set-up, Docker official images and lightweight Alpine Linux.

### Include (every service is optional as declared in the yml file)
* Apache with Php 7 and Xdebug
* MySQL/MariaDB and/or PostgreSQL
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

Access the stack dashboard on port 8181
<pre>
http://localhost:8181
</pre>

### Setup Drupal 8 with Composer

Setup a new Drupal 8 based on a composer template (yes it's slower than with
Drush but this is the good way!)
Include Drush and Drupal console.

<pre>
docker exec -it -u apache ddd-apache \
composer create-project drupal-composer/drupal-project:8.x-dev /www/drupal --stability dev --no-interaction
</pre>

### Install Drupal 8

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

#### Add some modules

<pre>
docker exec -it -u apache ddd-apache \
composer -d=/www/drupal require \
drupal/admin_toolbar drupal/ctools drupal/pathauto drupal/token drupal/panels
</pre>

### Enable some modules

<pre>
docker exec -it -u apache ddd-apache \
/www/drupal/vendor/bin/drush -y en \
--root=/www/drupal/web \
admin_toolbar ctools ctools_block ctools_views panels token pathauto
</pre>

## Access services

#### MySQL / PostgreSQL :
* Database host (from apache  container):
 * mysql
 * pgsql
* database name / user / pass: drupal

#### Solr :
* [http://localhost:8983/solr/#/drupal](http://localhost:8983/solr/#/drupal)

From the Apache container (Drupal config)
* Hostname
 * solr
* Core
 * drupal
* port
 * 8983

## Docker, Docker Compose basic usage

### See containers logs
<pre>cd THIS_PROJECT</pre>
<pre>docker-compose logs</pre>

See data/logs for specific services logs.

<pre>docker-compose logs apache</pre>

### Destroy containers (will loose drupal files!)
<pre>docker-compose stop && docker-compose down</pre>

### Remove your persistent data (and lost everything!)
<pre>sudo rm -rf data/database data/logs data/www/drupal</pre>

## Suggested tools

* [Opcache GUI](https://github.com/amnuts/opcache-gui)
* [Pimp my Log](http://pimpmylog.com/)
* [Phpmemcacheadmin](https://github.com/wp-cloud/phpmemcacheadmin)
* [Xdebug GUI](https://github.com/splitbrain/xdebug-trace-tree)
* [Adminer extended](https://github.com/dg/adminer-custom)

You can find a script in scripts/get-tools.sh folder to download or update all tools.
<pre>cd THIS_PROJECT</pre>
<pre>chmod +x scripts/get-tools.sh</pre>
<pre>./scripts/get-tools.sh</pre>

## Services access from host

* Adminer and other tools access:
 * [http://localhost/TOOLS](http://localhost/TOOLS)
* Mailhog access:
 * [http://localhost:8025](http://localhost:8025)
* Solr access:
 * [http://localhost:8983](http://localhost:8983)
* Ldap admin:
 * login: cn=admin,dc=example,dc=org
 * pass: admin
 * [http://localhost:6443](http://localhost:6443)
* More ldap info, see https://github.com/osixia/docker-openldap#environment-variables
