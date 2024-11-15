# Healthchecks.io

Setting up a [Healthchecks](https://healthchecks.io/docs/) container with e-mail notifications using Gmail.

# Resources

- [Healthchecks Docs](https://healthchecks.io/docs/)
- [Container Image](https://hub.docker.com/r/healthchecks/healthchecks)
- [Gmail App Passwords](https://support.google.com/mail/answer/185833?hl=en)

# Prerequisites

- You need an app password created for your gmail account you want to send emails from.

# Setup

1. Grab the docker-compose file from the container page. I'll show mine:

```yaml
version: "3"
services:
  healthchecks:
    image: healthchecks/healthchecks:latest
    container_name: healthchecks
    environment:
      - ALLOWED_HOSTS=*
      - DB=sqlite
      - DB_NAME=/data/hc.sqlite
      - DEBUG=True
      - DEFAULT_FROM_EMAIL=email@gmail.com
      - EMAIL_HOST=smtp.gmail.com
      - EMAIL_HOST_PASSWORD=qqqqwwwweeeerrrr
      - EMAIL_HOST_USER=email@gmail.com
      - EMAIL_PORT=587
      - EMAIL_USE_TLS=True
      - SECRET_KEY=---
      - SITE_ROOT=http://192.168.1.11:8000
    ports:
      - 8000:8000
    volumes:
      - healthchecks-data:/data
    restart: unless-stopped
volumes:
    healthchecks-data:
```
**NOTE**: When you create a gmail app password, it creates a 16 character password, and shows it to you like this: ``qqqq wwww eeee rrrr``. You need to enter it like above with no spaces, otherwise it won't work and you'll get the error: ``Server returned an error: 535-5.7.8 Username and Password not accepted``

2. Pull the image and once it's created, create the super-user account by running: 

`` docker-compose exec healthchecks /opt/healthchecks/manage.py createsuperuser``

# Creating an Example Check

1. There should be an example check created when you first setup healthchecks. You can also test out the email notifications under ``Integrations``.


    What I find useful about healthchecks is that you can signal the start and end of a task you want to be monitored. My use-case is to monitor cron jobs; Let's see an example.

2. We'll signal a start by appending ``/start`` to the url. To signal an end, simply omit the ``/start`` from the url. Here's an example cron job that rsyncs a directory from one drive to another.

```bash
#!/bin/bash
curl -fsS -m 10 --retry 5 -o /dev/null http://192.168.1.11:8000/ping/f77a6fc5-ca6c-49fe-bfcd-9e5f2da335dd/start

rsync --delete-after -avP /mnt/cache_ssd/Music/ /mnt/disk4/Music/

curl -fsS -m 10 --retry 5 -o /dev/null http://192.168.1.11:8000/ping/f77a6fc5-ca6c-49fe-bfcd-9e5f2da335dd
```

You'll need to configure the check with a proper grace period to get alerting. The healthchecks docs are easy to follow and show you how.