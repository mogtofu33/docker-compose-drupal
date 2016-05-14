# Drupal Docker development made easy

* see https://docs.docker.com/compose/
* More details on docker compose file: https://docs.docker.com/compose/compose-file

Focus on easy set-up and light images with Alpine Linux.

Include (every service is optionnal as declared in the yml file)
* Php5 or 7 with xdebug
* Apache and/or Nginx
* MySQL and/or PostgreSQL
* Memcache
* Mailhog
* Solr
* Ldap
* Varnish

Include Php Tools:
* Drush
* Drupal console
* Composer
* Adminer

Suggested tools:
* PimpMyLog
* phpMemcachedAdmin
* opcache gui
* Xdebug gui

## Quick launch new Drupal project

<pre>
# Clone this project.
git clone https://github.com/Mogtofu33/docker-compose-drupal.git docker-drupal
cd docker-drupal

# Create your compose file from template.
cp docker-compose.tpl docker-compose.yml

# Edit docker-compose.yml depending services you want.
vi docker-compose.yml

# Launch the containers.
docker-compose build && docker-compose up -d

# Check your containers statuses and names.
docker-compose ps
</pre>

<pre>
# Download and install Drupal 7 with MySQL, replace WEB_CONTAINER_NAME with the one running.
docker exec -it WEB_CONTAINER_NAME drush dl drupal-7 -y --destination=/www --drupal-project-rename 
docker exec -it WEB_CONTAINER_NAME drush @d si -y --db-url=mysql://drupal:drupal@mysql/drupal --account-name=admin --account-pass=password
</pre>

Got to your Drupal:

* [http://localhost/drupal](http://localhost/drupal)

MySQL / PostgreSQL :
* Database host (from apache or nginx):
 * mysql
 * pgsql
* database name / user / pass: drupal

Solr core (from apache or nginx):
* http://solr:8983/solr/drupal

## Quick launch existing Drupal project

Same as new project but:

Put your drupal site in data/www/drupal folder.

Put your database dump in data/www/TOOLS folder and rename in adminer.sql or adminer.sql.gz.

Got to adminer to import your databse on the drupal table :

<pre>http://localhost/TOOLS/adminer.php</pre>

Edit your settings.php to match settings below.

Got to your Drupal:

<pre>http://localhost/drupal</pre>

## See logs
<pre>docker-compose logs</pre>

Some applications logs will be stored opn data/logs.

## Destroy all
<pre>docker-compose stop && docker-compose down</pre>

## Services access

### See running services and get container names
<pre>docker-compose ps</pre>

### Execute command on any service
<pre>docker exec -it CONTAINER_NAME MY_CMD</pre>

### Bash access on services based on my images
<pre>docker exec -it CONTAINER_NAME bash</pre>

### Other images
<pre>docker exec -it CONTAINER_NAME /bin/sh</pre>

## Recommended tools

- PimpMyLog:

  - git clone https://github.com/potsky/PimpMyLog.git data/www/TOOLS/PimpMyLog

 - Copy config from config/pimpmylog

## Services access from host

* Mailhog access:
<pre>http://localhost:8025</pre>
* Solr access:
<pre>http://localhost:8983</pre>
* Ldap admin:
 * login: cn=admin,dc=example,dc=org
 * pass: admin

<pre>http://localhost:6443</pre>
* More ldap info, see https://github.com/osixia/docker-openldap#environment-variables

## More features on next release

* SSL on Apache / Nginx
* Data permissions fix setting host user uid/gid to service owner.
