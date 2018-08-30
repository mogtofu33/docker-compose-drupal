# Makefile for Docker Compose Drupal skeleton.

build:
	./app/vendor/bin/phar-builder package -o ./ ./app/composer.json;
	@mv ./app/dashboard.phar ./build/;
	@cp -r ./app/favicon.ico ./app/js ./app/css ./build/;

install:
	composer install --no-dev --working-dir=./app;

clean-install:
	rm -rf ./app/vendor/;
	rm -f ./app/composer.lock;

clean:
	rm -rf ./build/favicon.ico ./build/css ./build/js ./build/dashboard.phar;

.PHONY: build clean install clean-install
