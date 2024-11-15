# Self-Hosted Gitea Server

Guide to setting up a self-hosted Gitea server in an LXC containter on Proxmox

## Why?
- Having a private git repo with a frontend for projects seperate from Github
- Run the equivalent of Github Actions but locally

## Goals at the end of the day
- Have a local private Gitea Server running, accessible on the local network

## Resources
- [Gitea](https://gitea.io/en-us/)
- [Proxmox Helper Scripts - Gitea](https://tteck.github.io/Proxmox/#gitea-lxc)
- [Proxmox Helper Scripts - PostgreSQL](https://tteck.github.io/Proxmox/#postgresql-lxc)
- [PostgreSQL Post-Install](https://github.com/tteck/Proxmox/discussions/2916)
- [Permission Denied fix when initial Gitea setup](https://forum.gitea.com/t/gitea-postgres-with-docker-compose-sync-pq-permission-denied-for-schema-public/6439)

## Requirements
The Gitea LXC container doesn't have a database, so we need to set one up. We will use a PostgreSQL LXC container.

## How-To

### Installing PostgreSQL

1. Run the Proxmox Helper Script; Follow the prompts from the script and install Adminer

2. Follow the post-install guide up until creating the new database.

3. Create a new user named `gitea`
    - `CREATE USER gitea WITH PASSWORD 'your-password';`

4. Create a new database named `gitea`
    - `CREATE DATABASE gitea;`

5. Grant the user `gitea` access to the database `gitea`
    - `GRANT ALL ON DATABASE gitea TO gitea;`

6. Change the owner of the `gitea` database
    - `ALTER DATABASE gitea OWNER TO gitea;`

### Installing Gitea

1. Run the Proxmox Helper Script

## End

We should now have a running gitea server with a postgreSQL database