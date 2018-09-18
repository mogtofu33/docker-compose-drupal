# Makefile for Docker Compose Drupal skeleton.

UID=$$(id -u $$USER)
GID=$$(id -g $$USER)

build:
	@APACHE_IMAGE="mogtofu33/apache:latest" PHP_IMAGE="mogtofu33/php" MYSQL_IMAGE="mariadb:latest" PGSQL_IMAGE="postgres:alpine" envsubst < "./build/dcd/docker-compose.tpl.yml" > "./docker-compose.tpl.yml";
	@LOCAL_UID="1000" LOCAL_GID="1000" envsubst < "./build/dcd/env.template" > "./default.env";

setup: clean-setup
	@cp ./docker-compose.tpl.yml ./docker-compose.yml;
	@cp ./default.env ./.env;
	@sed -i "s/LOCAL_UID=1000/LOCAL_UID=$(UID)/g" ./.env;
	@sed -i "s/LOCAL_GID=1000/LOCAL_GID=$(GID)/g" ./.env;

up: build setup
	@docker-compose up -d --build;

clean:
	@rm -f ./docker-compose.tpl.yml;
	@rm -f ./default.env;

clean-setup:
	@rm -f ./docker-compose.yml;
	@rm -f ./.env;

nuke: clean-setup
	@sudo rm -rf data;

.PHONY: build setup up clean nuke
