# Makefile for Docker Compose Drupal skeleton.

UID=$$(id -u $$USER)
GID=$$(id -g $$USER)

setup: clean-setup
	@cp ./docker-compose.tpl.yml ./docker-compose.yml;
	@cp ./default.env ./.env;
	@sed -i "s/LOCAL_UID=1000/LOCAL_UID=$(UID)/g" ./.env;
	@sed -i "s/LOCAL_GID=1000/LOCAL_GID=$(GID)/g" ./.env;

up: setup
	@docker-compose up -d --build;

clean:
	@rm -f ./docker-compose.tpl.yml;
	@rm -f ./default.env;

clean-setup:
	@rm -f ./docker-compose.yml;
	@rm -f ./.env;

demo: setup
	@cp -f ./samples/apache_mysql_php.yml ./docker-compose.yml;
	@docker-compose up -d --build;
	@sleep 15s;
	@scripts/install-drupal.sh install drupal-demo;

nuke: clean-setup
	@sudo rm -rf drupal;

.PHONY: setup up clean nuke demo
