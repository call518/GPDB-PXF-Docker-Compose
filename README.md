# Greenplum Database single node with PXF Docker image

This is a simple Greenplum Database single node with PXF Docker image for **local development and testing ONLY**.

[DockerHub](https://hub.docker.com/r/pro100filipp/greenplum-with-pxf)

## How to use this image

### Start a Greenplum instance

```console
docker run --name some-gpdb -d pro100filipp/greenplum-with-pxf
```

The default `postgres` user with password `postgres` and database `test` are created in the entrypoint with `psql` script.

## ... via [`docker-compose`](https://github.com/docker/compose)

Example `docker-compose.yml`:

```yaml
version: '3'

services:

  gpdb:
    image: pro100filipp/greenplum-with-pxf
    restart: always
    ports:
      - "5432:5432"
    environment:
      GP_DB: example_db
      GP_USER: myuser
      GP_PASSWORD: mypassword
    volumes:
      - data:/srv
volumes:
  data:
```

Run `docker-compose -f docker-compose.yml up`, wait for it to initialize completely, and try to connect to database at `5432` port with any appropriate way (`psql`, DataGrip, DBeaver, pgAdmin, etc).

## How to extend this image

### Environment Variables

This image uses several environment variables that can be left intact because all of them are optional and have default values.

**Warning**: the Docker specific variables will only have an effect if you start the container with a data directory that is empty; any pre-existing database will be left untouched on container startup.

#### `GP_PASSWORD`

This optional environment variable sets the regular user password for Greenplum DB. The default password is `postgres` and the user is defined by the `GP_USER` environment variable.

**Note 1:** The image sets up `trust` authentication locally so you may notice a password is not required when connecting from `localhost` (inside the same container). However, a password will be required if connecting from a different host/container.

#### `GP_USER`

This optional environment variable is used to set a user. This variable will create the specified user and grant access to default database provided by `GP_DB`. If it is not specified, then the default user of `postgres` will be used.

#### `GP_DB`

This optional environment variable can be used to define a different name for the default database that is created when the image is first started. If it is not specified, then `test` will be used.

## Caveats

### Where to Store Data

**Important note:** There are several ways to store data used by applications that run in Docker containers:

- Let Docker manage the storage of your database data [by writing the database files to disk on the host system using its own internal volume management](https://docs.docker.com/storage/volumes/). This is the default and is easy and fairly transparent to the user. The downside is that the files may be hard to locate for tools and applications that run directly on the host system, i.e. outside containers.
- Create a data directory on the host system (outside the container) and [mount this to a directory visible from inside the container](https://docs.docker.com/storage/bind-mounts/). This places the database files in a known location on the host system, and makes it easy for tools and applications on the host system to access the files. The downside is that the user needs to make sure that the directory exists, and that e.g. directory permissions and other security mechanisms on the host system are set up correctly.

Example of the basic procedure here for the latter option above:

1. Create a data directory on a suitable volume on your host system, e.g. `/my/own/datadir`.
2. Start your `pro100filipp/greenplum-with-pxf` container like this:

 ```console
 docker run --name gpdb -v /my/own/datadir:/srv -d pro100filipp/greenplum-with-pxf:tag
 ```

The `-v /my/own/datadir:/srv` part of the command mounts the `/my/own/datadir` directory from the underlying host system as `/srv` inside the container, where Greenplum DB cluster will write its data files.
