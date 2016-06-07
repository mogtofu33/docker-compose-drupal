# Drupal Docker development made easy

Require:

* Docker engine: https://docs.docker.com/engine/installation/
* Docker compose: https://docs.docker.com/compose/install/

Focus on easy set-up and light images with Alpine Linux.

## Features
* Easy to launch, include all base tools for Drupal
* Code, data and logs persistence
* Simple config override for main services
* Base Php / Apache / Nginx images with bash and custom PS1 (docker exec -it CONTAINER_NAME bash)
* Light images (based on Alpine Linux)
* One service by containers

### Include (every service is optionnal as declared in the yml file)
* Php 5.6 or 7 with Xdebug
* Apache and/or Nginx
* MySQL/MariaDB and/or PostgreSQL
* Memcache
* Mailhog
* Solr
* Ldap
* Varnish

### Include Drupal/Php Tools:
* Drush
* Drupal console
* Composer
* Adminer

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
cp config.env .env

# Edit your configuration
vi .env

# Check the config
docker-compose config

# Launch the containers.
docker-compose build && docker-compose up -d
</pre>

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
* Database host (from apache or nginx container):
 * mysql
 * pgsql
* database name / user / pass: drupal

#### Solr core (from apache or nginx container):
* [http://solr:8983/solr/drupal](http://solr:8983/solr/drupal)

## Using Drush with your web container

An aliases file is availbale from data/drush, it contains a simple alias @d for the default Drupal in www/drupal.

Using docker exec you can run a command directly in the container, for example:
<pre>docker exec -it CONTAINER_NAME drush @d st</pre>

To avoid permissions issues you can run command as webserver user, for example with apache:
<pre>docker exec -it -u apache:www-data CONTAINER_NAME drush @d st</pre>

with Nginx/Phpfpm, CONTAINER_NAME should be ending with phpfpm_1:
<pre>docker exec -it -u phpfpm:phpfpm CONTAINER_NAME drush @d st</pre>

You can find a script to set a Drush alias for your container :
<pre>. scripts/start-drush.sh</pre>
Every drush command will now run on this container.

When you finish your work on this stack:
<pre>. scripts/end-drush.sh</pre>

## See containers logs
<pre>docker-compose logs</pre>

See data/logs for specific services logs.

## Destroy containers
<pre>docker-compose stop && docker-compose down</pre>

## Remove your data (and lost everything !)
<pre>sudo rm -rf data/database data/logs data/www/drupal</pre>

## Containers access

### See running services and get container names
<pre>docker-compose ps</pre>

### Execute command on any service
<pre>docker exec -it CONTAINER_NAME MY_CMD</pre>

### Bash access on services based on my images
<pre>docker exec -it CONTAINER_NAME bash</pre>

### Other images (not from my base)
<pre>docker exec -it CONTAINER_NAME /bin/sh</pre>

## Suggested tools

You can find a script in scripts/get-tools.sh folder to download or update all tools.

- PimpMyLog:
<pre>git clone https://github.com/potsky/PimpMyLog.git data/www/TOOLS/PimpMyLog</pre>

 - Copy config from config/pimpmylog

- phpMemcachedAdmin
<pre>git clone https://github.com/wp-cloud/phpmemcacheadmin.git data/www/TOOLS/PhpMemcachedAdmin</pre>

  - (Change config 127.0.0.1 to memcache)

- opcache gui
<pre>git clone https://github.com/amnuts/opcache-gui.git data/www/TOOLS/Opcache-gui</pre>

- Xdebug gui
<pre>git clone https://github.com/splitbrain/xdebug-trace-tree.git data/www/TOOLS/Xdebug-trace</pre>

- Adminer with plugins and design
<pre>git clone https://github.com/dg/adminer-custom.git data/www/TOOLS/adminer</pre>

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

## More features/fix on next release

* Phpfpm permission
* SSL on Apache / Nginx
* Add script to ease Drupal full setup ?
