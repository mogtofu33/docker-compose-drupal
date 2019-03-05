# Simple minimal dashboard for Docker Compose Drupal

Give minimal links and information for Drupal, PHP and services in Docker Compose Drupal.

Based on [Docker SDK for Python](https://docker-py.readthedocs.io/en/stable/)

## Build

### Assets

```bash
docker run -it --rm -u node -v $(pwd):/home/node/app -w /home/node/app node:lts-alpine npm install --save
docker run -it --rm -u node -v $(pwd):/home/node/app -w /home/node/app node:lts-alpine npm run build
# Unminified version
docker run -it --rm -u node -v $(pwd):/home/node/app -w /home/node/app node:lts-alpine npm run build:dev
```

### Build and push Docker

```bash
docker build --pull --tag mogtofu33/dashboard:latest .
# Gitlab
docker login -u mog33 registry.gitlab.com
docker push registry.gitlab.com/mog33/docker-compose-drupal/dashboard:latest
# Docker hub
docker push mogtofu33/dashboard:latest
```
