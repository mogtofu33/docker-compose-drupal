# Makefile for Docker Compose Drupal skeleton, run 'make build'.
# Note Ubuntu 18 Docker repo is currently not working, works fine with xenial
# need to be moved to bionic when ready.

include .env

build:
	@UBUNTU_VERSION="16" UBUNTU_NAME="xenial" DOCKER_COMPOSE="${DOCKER_COMPOSE}" PHP_VERSION="${PHP_VERSION_16}" TIMEZONE="${TIMEZONE}" envsubst < "cloud-config.yml.template" > "cloud-config.ubuntu16.yml";
	@UBUNTU_VERSION="18" UBUNTU_NAME="bionic" DOCKER_COMPOSE="${DOCKER_COMPOSE}" PHP_VERSION="${PHP_VERSION_18}" TIMEZONE="${TIMEZONE}" envsubst < "cloud-config.yml.template" > "cloud-config.ubuntu18.yml";

.PHONY: build
