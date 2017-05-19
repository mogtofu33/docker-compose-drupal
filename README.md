# Drupal Docker Development

## Require

* Docker engine 1.13+: https://docs.docker.com/engine/installation/
* Docker compose 1.13+: https://docs.docker.com/compose/install/

## Introduction

Focus on easy set-up, lightweight images based on [Alpine Linux](https://alpinelinux.org/) and easy to use tools.

### Include (every service is optional as declared in the yml file)
* Apache with Php 5.6 or 7 with Xdebug
* MySQL/MariaDB and/or PostgreSQL
* Memcache
* [Mailhog](https://github.com/mailhog/MailHog)
* [Solr](http://lucene.apache.org/solr/)
* [OpenLdap](https://www.openldap.org/)
* [Varnish](https://varnish-cache.org/)

### Include Drupal/Php Tools
* [Drush](http://www.drush.org)
* [Drupal console](https://drupalconsole.com)
* [Composer](https://getcomposer.org)
* [Adminer](https://www.adminer.org)

### Include Linux script to get and configure
* [Opcache GUI](https://github.com/amnuts/opcache-gui)
* [Pimp my Log](http://pimpmylog.com/)
* [Phpmemcacheadmin](https://github.com/wp-cloud/phpmemcacheadmin)
* [Xdebug GUI](https://github.com/splitbrain/xdebug-trace-tree)
* [Adminer extended](https://github.com/dg/adminer-custom)

## Quick launch new Drupal project

<pre>
# Clone this project.
git clone https://github.com/Mogtofu33/docker-compose-drupal.git docker-drupal
cd docker-drupal

# Create your docker compose file from template.
cp docker-compose.tpl.yml docker-compose.yml

# Edit, remove or add services
vi docker-compose.yml

# Create your config file from template.
cp default.env .env

# Edit your configuration and enable third party tools if needed
# (Composer, Drush, Drupal console)
vi .env

# Check the config
docker-compose config

# Launch the containers.
docker-compose build && docker-compose up -d
</pre>

## Linux host with bash
Source drush script (see "section Using Drush with your web container")
<pre>. scripts/start-drush.sh</pre>

Download and install Drupal 7 with Apache and MySQL (when drush script sourced):

(Change drupal-7 to drupal for last 8.x release)
<pre>
drush dl drupal-7 -y --destination=/www --drupal-project-rename
drush si -y --db-url=mysql://drupal:drupal@mysql/drupal --account-name=admin --account-pass=password
</pre>

#### Go to your Drupal, login with admin/password:

* [http://localhost/drupal](http://localhost/drupal)

#### MySQL / PostgreSQL :
* Database host (from apache  container):
 * mysql
 * pgsql
* database name / user / pass: drupal

#### Solr core (from apache container):
* [http://solr:8983/solr/drupal](http://solr:8983/solr/drupal)

## Using Drush with your web container (If Drush is enable in your .env)

An aliases file is available from data/drush, it contains a simple alias @d for the default Drupal in www/drupal.
_Note_: Drush tables output is malformated when using alias, currently work best with --root=/www/drupal

Using docker exec you can run a command directly in the container as apache user, for example:
<pre>docker exec -it -u apache CONTAINER_NAME drush --root=/www/drupal status</pre>

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
