# Makefile for Docker Compose Drupal skeleton.

include .env

build:
	@UBUNTU_VERSION="16" DOCKER_COMPOSE="${DOCKER_COMPOSE}" PHP_VERSION="${PHP_VERSION_16}" envsubst < "cloud-config.yml.template" > "cloud-config.ubuntu16.yml";
	@UBUNTU_VERSION="18" DOCKER_COMPOSE="${DOCKER_COMPOSE}" PHP_VERSION="${PHP_VERSION_18}" envsubst < "cloud-config.yml.template" > "cloud-config.ubuntu18.yml";

.PHONY: build
