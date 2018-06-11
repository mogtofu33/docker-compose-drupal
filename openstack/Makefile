# Makefile for Docker Compose Drupal skeleton.
# Note Ubuntu 18 Docker repo is currently not working, works fine with xenial
# need to be moved to biuonic when ready.

include .env

build:
  @UBUNTU_VERSION="16" @UBUNTU_NAME="xenial" DOCKER_COMPOSE="${DOCKER_COMPOSE}" PHP_VERSION="${PHP_VERSION_16}" envsubst < "cloud-config.yml.template" > "cloud-config.ubuntu16.yml";
  @UBUNTU_VERSION="18" @UBUNTU_NAME="xenial" DOCKER_COMPOSE="${DOCKER_COMPOSE}" PHP_VERSION="${PHP_VERSION_18}" envsubst < "cloud-config.yml.template" > "cloud-config.ubuntu18.yml";

.PHONY: build
