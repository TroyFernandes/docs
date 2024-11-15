# Docker Context

How to manage another docker instance e.g. deploy/manage docker compose files on a Raspberry Pi

# Resources

- [Docker Context](https://www.docker.com/blog/how-to-deploy-on-remote-docker-hosts-with-docker-compose/)

# Prerequisites

You should set up passwordless ssh access between your machines.

# Adding a Remote Context

1. Create the context: ``docker context create dietpi1 --docker "host=ssh://root@192.168.1.11"``

2. View the new context using: ``docker context ls``
```shell
/c/Windows/System32 ❯ docker context ls
NAME              DESCRIPTION                               DOCKER ENDPOINT                             ERROR
default           Current DOCKER_HOST based configuration   npipe:////./pipe/docker_engine
desktop-linux *   Docker Desktop                            npipe:////./pipe/dockerDesktopLinuxEngine
dietpi1                                                     ssh://root@192.168.1.11
```

3. If you need to update the context:
``
docker context update --description "RaspberryPi 3b; DietPi" --docker "host=ssh://root@192.168.1.11" dietpi1
``

# Deploying a Container to the Remote

Simply create your docker compose file and run: ``docker-compose --context dietpi1 up -d``