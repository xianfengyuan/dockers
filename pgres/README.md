[![Circle CI](https://circleci.com/gh/sameersbn/docker-postgresql.svg?style=svg)](https://circleci.com/gh/sameersbn/docker-postgresql) [![Docker Repository on Quay.io](https://quay.io/repository/sameersbn/postgresql/status "Docker Repository on Quay.io")](https://quay.io/repository/sameersbn/postgresql)

# Table of Contents

- [Introduction](#introduction)
- [Changelog](Changelog.md)
- [Contributing](#contributing)
- [Reporting Issues](#reporting-issues)
- [Installation](#installation)
- [Quick Start](#quick-start)
- [Persistence](#persistence)
- [Creating User and Database at Launch](#creating-user-and-database-at-launch)
- [Creating a Snapshot or Slave Database](#creating-a-snapshot-or-slave-database)
- [Host UID / GID Mapping](#host-uid--gid-mapping)
- [Upgrading](#upgrading)
- [Shell Access](#shell-access)

# Introduction

Dockerfile to build a PostgreSQL container image which can be linked to other containers.

# Contributing

If you find this image useful here's how you can help:

- Send a Pull Request with your awesome new features and bug fixes
- Help new users with [Issues](https://github.com/sameersbn/docker-postgresql/issues) they may encounter
- Support the development of this image with a [donation](http://www.damagehead.com/donate/)

# Reporting Issues

Docker is a relatively new project and is being actively developed and tested by a thriving community of developers and testers and every release of Docker features many enhancements and bugfixes.

Given the nature of the development and release cycle it is very important that you have the latest version of docker installed because any issue that you encounter might have already been fixed with a newer docker release.

For ubuntu users I suggest [installing docker](https://docs.docker.com/installation/ubuntulinux/) using docker's own package repository since the version of docker packaged in the ubuntu repositories are a little dated.

Here is the shortform of the installation of an updated version of docker on ubuntu.

```bash
sudo apt-get purge docker.io
curl -s https://get.docker.io/ubuntu/ | sudo sh
sudo apt-get update
sudo apt-get install lxc-docker
```

Fedora and RHEL/CentOS users should try disabling selinux with `setenforce 0` and check if resolves the issue. If it does than there is not much that I can help you with. You can either stick with selinux disabled (not recommended by redhat) or switch to using ubuntu.

If using the latest docker version and/or disabling selinux does not fix the issue then please file a issue request on the [issues](https://github.com/sameersbn/docker-postgresql/issues) page.

In your issue report please make sure you provide the following information:

- The host distribution and release version.
- Output of the `docker version` command
- Output of the `docker info` command
- The `docker run` command you used to run the image (mask out the sensitive bits).

# Installation

Automated builds of the image are available on [Dockerhub](https://hub.docker.com/r/sameersbn/postgresql) and is the recommended method of installation.

> **Note**: Builds are also available on [Quay.io](https://quay.io/repository/sameersbn/postgresql)

```bash
docker pull sameersbn/postgresql:9.4-8
```

Alternately you can build the image yourself.

```bash
docker build -t sameersbn/postgresql github.com/sameersbn/docker-postgresql
```

# Quick Start

Run the postgresql image

```bash
docker run --name postgresql -d sameersbn/postgresql:9.4-8
```

The simplest way to login to the postgresql container as the administrative `postgres` user is to use the `docker exec` command to attach a new process to the running container and connect to the postgresql server over the unix socket.

```bash
docker exec -it postgresql sudo -u postgres psql
```

# Persistence

For data persistence a volume should be mounted at `/var/lib/postgresql`.

SELinux users are also required to change the security context of the mount point so that it plays nicely with selinux.

```bash
mkdir -p /opt/postgresql/data
sudo chcon -Rt svirt_sandbox_file_t /opt/postgresql/data
```

The updated run command looks like this.

```bash
docker run --name postgresql -d \
  -v /opt/postgresql/data:/var/lib/postgresql sameersbn/postgresql:9.4-8
```

This will make sure that the data stored in the database is not lost when the image is stopped and started again.

# Creating User and Database at Launch

The image allows you to create a user and database at launch time.

To create a new user you should specify the `DB_USER` and `DB_PASS` variables. The following command will create a new user *dbuser* with the password *dbpass*.

```bash
docker run --name postgresql -d \
  -e 'DB_USER=dbuser' -e 'DB_PASS=dbpass' \
  sameersbn/postgresql:9.4-8
```

**NOTE**
- If the password is not specified the user will not be created
- If the user user already exists no changes will be made

Similarly, you can also create a new database by specifying the database name in the `DB_NAME` variable.

```bash
docker run --name postgresql -d \
  -e 'DB_NAME=dbname' sameersbn/postgresql:9.4-8
```

You may also specify a comma separated list of database names in the `DB_NAME` variable. The following command creates two new databases named *dbname1* and *dbname2* (p.s. this feature is only available in releases greater than 9.1-1).

```bash
docker run --name postgresql -d \
  -e 'DB_NAME=dbname1,dbname2' \
  sameersbn/postgresql:9.4-8
```

If the `DB_USER` and `DB_PASS` variables are also specified while creating the database, then the user is granted access to the database(s).

For example,

```bash
docker run --name postgresql -d \
  -e 'DB_USER=dbuser' -e 'DB_PASS=dbpass' -e 'DB_NAME=dbname' \
  sameersbn/postgresql:9.4-8
```

will create a user *dbuser* with the password *dbpass*. It will also create a database named *dbname* and the *dbuser* user will have full access to the *dbname* database.

The `DB_LOCALE` environment variable can be used to configure the locale used for database creation. Its default value is set to C.

The `PSQL_TRUST_LOCALNET` environment variable can be used to configure postgres to trust connections on the same network.  This is handy for other containers to connect without authentication. To enable this behavior, set `PSQL_TRUST_LOCALNET` to `true`.

For example,

```bash
docker run --name postgresql -d \
  -e 'PSQL_TRUST_LOCALNET=true' \
  sameersbn/postgresql:9.4-8
```

This has the effect of adding the following to the `pg_hba.conf` file:

```
host    all             all             samenet                 trust
```

# Creating a Snapshot or Slave Database

You may use the `PSQL_MODE` variable along with `REPLICATION_HOST`, `REPLICATION_PORT`, `REPLICATION_USER` and `REPLICATION_PASS` to create a snapshot of an existing database and enable stream replication.

Your master database must support replication or super-user access for the credentials you specify. The `PSQL_MODE` variable should be set to `master`, for replication on your master node and `slave` or `snapshot` respectively for streaming replication or a point-in-time snapshot of a running instance.

Create a master instance

```bash
docker run --name='psql-master' -it --rm \
  -e 'PSQL_MODE=master' -e 'PSQL_TRUST_LOCALNET=true' \
  -e 'REPLICATION_USER=replicator' -e 'REPLICATION_PASS=replicatorpass' \
  -e 'DB_NAME=dbname' -e 'DB_USER=dbuser' -e 'DB_PASS=dbpass' \
  sameersbn/postgresql:9.4-8
```

Create a streaming replication instance

```bash
docker run --name='psql-slave' -it --rm  \
  --link psql-master:psql-master  \
  -e 'PSQL_MODE=slave' -e 'PSQL_TRUST_LOCALNET=true' \
  -e 'REPLICATION_HOST=psql-master' -e 'REPLICATION_PORT=5432' \
  -e 'REPLICATION_USER=replicator' -e 'REPLICATION_PASS=replicatorpass' \
  sameersbn/postgresql:9.4-8
```

# Enable Unaccent (Search plain text with accent)

Unaccent is a text search dictionary that removes accents (diacritic signs) from lexemes. It's a filtering dictionary, which means its output is always passed to the next dictionary (if any), unlike the normal behavior of dictionaries. This allows accent-insensitive processing for full text search.

By default unaccent is configure to `false`

```bash
docker run --name postgresql -d \
  -e 'DB_UNACCENT=true' \
  sameersbn/postgresql:9.4-8
```

# Host UID / GID Mapping

Per default the container is configured to run postgres as user and group `postgres` with some unknown `uid` and `gid`. The host possibly uses these ids for different purposes leading to unfavorable effects. From the host it appears as if the mounted data volumes are owned by the host's user/group `[whatever id postgres has in the image]`.

Also the container processes seem to be executed as the host's user/group `[whatever id postgres has in the image]`. The container can be configured to map the `uid` and `gid` of `postgres` to different ids on host by passing the environment variables `USERMAP_UID` and `USERMAP_GID`. The following command maps the ids to user and group `postgres` on the host.

```bash
docker run --name=postgresql -it --rm [options] \
  --env="USERMAP_UID=$(id -u postgres)" --env="USERMAP_GID=$(id -g postgres)" \
  sameersbn/postgresql:9.4-8
```


# Upgrading

To upgrade to newer releases, simply follow this 3 step upgrade procedure.

- **Step 1**: Stop the currently running image

```bash
docker stop postgresql
```

- **Step 2**: Update the docker image.

```bash
docker pull sameersbn/postgresql:9.4-8
```

- **Step 3**: Start the image

```bash
docker run --name postgresql -d [OPTIONS] sameersbn/postgresql:9.4-8
```

# Shell Access

For debugging and maintenance purposes you may want access the containers shell. If you are using docker version `1.3.0` or higher you can access a running containers shell using `docker exec` command.

```bash
docker exec -it postgresql bash
```

If you are using an older version of docker, you can use the [nsenter](http://man7.org/linux/man-pages/man1/nsenter.1.html) linux tool (part of the util-linux package) to access the container shell.

Some linux distros (e.g. ubuntu) use older versions of the util-linux which do not include the `nsenter` tool. To get around this @jpetazzo has created a nice docker image that allows you to install the `nsenter` utility and a helper script named `docker-enter` on these distros.

To install `nsenter` execute the following command on your host,

```bash
docker run --rm -v /usr/local/bin:/target jpetazzo/nsenter
```

Now you can access the container shell using the command

```bash
sudo docker-enter postgresql
```

For more information refer https://github.com/jpetazzo/nsenter
