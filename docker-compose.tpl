################################################################################
# Docker compose Drupal full dev stack.
#
# A single Docker compose file that try to simply and quickly setup a full
# Drupal development environment.
#
# Project page:
#   https://github.com/Mogtofu33/docker-compose-drupal
#
# Check your config after editing this file with:
#   docker-compose config
#
# All custom settings are in config folder, check and adapt to your needs.
#
# For more information on docker compose file structure:
# @see https://docs.docker.com/compose/
#
################################################################################

##
# Choose Apache or Nginx-PhpFpm, you can run both if you change host ports.
# docker-alpine-nginx: Nginx 1.8.1
# docker-alpine-edge-nginx: Nginx 1.10.0
##
nginx:
  image: mogtofu33/docker-alpine-nginx
#  image: mogtofu33/docker-alpine-edge-nginx
# Set host port to access your Drupal.
  ports:
    - "80:80"
  links:
    - phpfpm
# Choose one database or both.
    - mysql
#    - pgsql
    - memcache
    - mailhog
    - solr
  volumes_from:
    - data
  volumes:
    - ./config/nginx/nginx.conf:/etc/nginx/nginx.conf
    - ./data/logs:/var/log/nginx
    - ./config/drush:/etc/drush
# Set your host user uid/gid to fix permissions.
#  environment:
#    - LOCAL_UID=1000
#    - LOCAL_GID=1000

##
# Optionnal Php-fpm 5.6 or Php-fpm 7 images, uncomment as needed.
##
phpfpm:
  image: mogtofu33/docker-alpine-phpfpm
#  image: mogtofu33/docker-alpine-phpfpm7
  expose:
    - "9000"
  links:
# Choose one database or both.
    - mysql
#    - pgsql
    - memcache
    - mailhog
    - solr
  volumes_from:
    - data
  volumes:
   - ./config/php/php-fpm-nginx.conf:/etc/php/php-fpm.conf
   - ./config/php/conf.d:/etc/php/conf.d
#   - ./config/php7/php-fpm-nginx.conf:/etc/php/php-fpm.conf
#   - ./config/php7/conf.d:/etc/php/conf.d
   - ./data/logs:/var/log/php
# Set your host user uid/gid to fix permissions.
#  environment:
#    - LOCAL_UID=1000
#    - LOCAL_GID=1000

##
# Optionnal Php 5.6 or Php 7 with Apache, uncomment as needed.
##
apache:
  image: mogtofu33/docker-alpine-php-apache
#  image: mogtofu33/docker-alpine-php7-apache
# Set host port to access your Drupal, if running nginx choose a different port.
  ports:
    - "80:80"
  links:
# Choose one database or both.
    - mysql
#    - pgsql
    - memcache
    - mailhog
    - solr
  volumes_from:
    - data
  volumes:
    - ./config/apache:/etc/apache2/vhost
    - ./config/php/conf.d:/etc/php/conf.d
#    - ./config/php7/conf.d:/etc/php/conf.d
    - ./data/logs:/var/log/apache2
    - ./config/drush:/etc/drush
# Set your host user uid/gid to fix permissions.
#  environment:
#    - LOCAL_UID=1000
#    - LOCAL_GID=1000

##
# Choose one of the database, you can run both if you want.
# For a direct access from host, remove expose and add ports definition:
# ports:
#   - "3306:3306"
##
mysql:
  image: mogtofu33/docker-alpine-mariadb
  expose:
    - "3306"
  volumes_from:
    - db
  volumes:
    - ./config/mysql:/etc/mysql
    - ./data/logs:/var/log/mysql
  environment:
    - MYSQL_DATABASE=drupal
    - MYSQL_USER=drupal
    - MYSQL_PASSWORD=drupal
    - MYSQL_ROOT_PASSWORD=root
# Set your host user uid/gid to fix permissions.
#    - LOCAL_UID=1000
#    - LOCAL_GID=1000

pgsql:
  image: mogtofu33/docker-alpine-postgres
  expose:
    - "5432"
  volumes_from:
    - db
  environment:
    - POSTGRES_USER=drupal
    - POSTGRES_PASSWORD=drupal
    - POSTGRES_DB=drupal
# Set your host user uid/gid to fix permissions.
#    - LOCAL_UID=1000
#    - LOCAL_GID=1000

##
# Other optionnal images, if you remove them do not forget to remove links:.
##
memcache:
  image: bpressure/alpine-memcached
# Comments expose and uncomment ports for an access from host.
#  ports:
#    - "11211:11211"
  expose:
    - "11211"
##
# Solr administration:
#   http://localhost:8983
#
# Shipped with a drupal core with drupal configuration from solr module.
# Solr core access from apache/nginx container:
#   http://solr:8983/solr/drupal
##
solr:
  image : mogtofu33/docker-alpine-solr
  ports:
    - "8983:8983"
  volumes:
    - ./data/logs:/var/log/solr
##
# Mailhog access from host:
#   http://localhost:8025
#
# config/zz-php.ini is set to use mailhog:
#   sendmail_path = /usr/sbin/sendmail -t -i -S mailhog:1025
##
mailhog:
  image: diyan/mailhog
  expose:
    - "1025"
  ports:
    - "8025:8025"

# Data and Db storage containers.
data:
  image: tianon/true
  volumes:
    - ./data/www:/www
db:
  image: tianon/true
  volumes:
    - ./data/database/mysql:/var/lib/mysql
    - ./data/database/pgsql:/var/lib/postgresql/data

##
# Optionnal Varnish.
# Uncomment to use, change apache or nginx ports to 8080:80 to get access w/o
# Varnish.
#
# Optionnal: 6082 is used for Terminal, VARNISH_BACKEND_IP must be set to
# container ip as reference 'apache' does not seems to work.
##
#varnish:
#  build: ./build/varnish
#  ports:
#    - "80:80"
##    - "6082:6082"
#  links:
#    - apache
#  volumes:
#    - ./data/logs:/var/log/varnish
#  environment:
#    - VARNISH_MEMORY=128M
##    - VARNISH_BACKEND_IP=apache

##
# Optionnal Ldap service with administration.
# Phpldapadmin access from:
#   http://localhost:6443
#
# See all available ldap anvironment variables from:
#   https://github.com/osixia/docker-openldap#environment-variables
#
# PHPLDAPADMIN_LDAP_HOSTS should be set to container ip as 'ldap' reference
# does not seem to work.
##
#ldap:
#  image: osixia/openldap:1.1.2
#  ports:
#    - "389:389"
#  environment:
#    - LDAP_ADMIN_PASSWORD=admin
#ldapadmin:
#  image: osixia/phpldapadmin:0.6.8
#  links:
#    - ldap
#  ports:
#    - "6443:443"
#  environment:
#    - PHPLDAPADMIN_LDAP_HOSTS=ldap

