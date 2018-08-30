# Makefile for Docker Compose Drupal skeleton.

build:
	@APACHE_IMAGE="mogtofu33/apache:latest" PHP_IMAGE="mogtofu33/php" MYSQL_IMAGE="mariadb:latest" PGSQL_IMAGE="postgres:alpine" envsubst < "./build/dcd/docker-compose.tpl" > "./docker-compose.tpl.yml";
	@LOCAL_UID="1000" LOCAL_GID="1000" envsubst < "./build/dcd/env.template" > "./default.env";

test-local-images:
	@APACHE_IMAGE="test_apache" PHP_IMAGE="test_php_7_2" MYSQL_IMAGE="mariadb:latest" PGSQL_IMAGE="postgres:alpine" envsubst < "./build/dcd/docker-compose.tpl" > "./docker-compose.test.yml";

test:
	cp ./docker-compose.tpl.yml ./docker-compose.yml;
	cp ./default.env ./.env;
	@sed -i 's/1000/1001/g' ./.env;
	##### Test config #####
	docker-compose config;

test-dashboard:
	@sed -i 's#dashboard/build#dashboard/app#g' ./docker-compose.yml;

run-test: build test
	docker-compose up;

clean:
	rm -f ./docker-compose.tpl.yml;
	rm -f ./default.env;

clean-test:
	# docker-compose stop;
	# docker-compose down;
	rm -f ./docker-compose.yml;
	rm -f ./docker-compose.test.yml;
	rm -f ./.env;

.PHONY: build test-local-images test test-dashboard run-test clean clean-test
