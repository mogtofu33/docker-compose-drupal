# Full Drupal Docker development stack

Focus on easy set-up and light images with Alpine Linux.

* see https://docs.docker.com/compose/

Include (every service is optionnal)
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

## Quick launch new Drupal project

Clone this project.

Copy and rename docker-compose.yml.MODEL to docker-compose.yml.

Edit docker-compose.yml depending services you want, be carefull of links sections.

Download your drupal site in data/www/drupal folder.

<pre>docker-compose up -d</pre>

Got to Drupal install:

<pre>http://localhost/drupal</pre>

Mysql / PostgreSQL :
* database name / user / pass: drupal

Solr core: drupal

## Quick launch existing Drupal project

Same as new project but:

Put your drupal site in data/www/drupal folder.

Put your database dump in data/www/TOOLS folder and rename in adminer.sql or adminer.sql.gz.

Got to adminer to import your databse on the drupal table :

<pre>http://localhost/TOOLS/adminer.php</pre>

Edit your settings.php to match settings below.

Got to your Drupal:

<pre>http://localhost/drupal</pre>

Mysql / PostgreSQL :
* database name / user / pass: drupal

Solr core: drupal

## See logs
<pre>docker-compose logs</pre>

Some applications logs will be stored opn data/logs.

## Destroy all
<pre>docker-compose stop && docker-compose down</pre>

## See runing services
<pre>docker-compose ps</pre>

## Execute command on any service
<pre>docker exec -it CONTAINER_NAME MY_CMD</pre>

## Bash access on services based on my images
<pre>docker exec -it CONTAINER_NAME bash</pre>

## Other images
<pre>docker exec -it CONTAINER_NAME /bin/sh</pre>

## Recommended tools

- PimpMyLog:

  - git clone https://github.com/potsky/PimpMyLog.git data/www/TOOLS/PimpMyLog

 - Copy config from config/pimpmylog

## Services access

* Mailhog access:
<pre>http://localhost:8025</pre>
* Solr access:
<pre>http://localhost:8983</pre>
* Ldap admin:
<pre>http://localhost:6443</pre>
* More ldap info, see https://github.com/osixia/docker-openldap#environment-variables
