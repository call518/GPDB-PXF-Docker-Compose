FROM ubuntu:bionic
SHELL ["/bin/bash", "-c"]

# Greenplum installation
ENV MALLOC_ARENA_MAX=1
ENV TZ=UTC
ENV DEBIAN_FRONTEND=noninteractive
ENV GP_DB=test
ENV GP_USER=postgres
ENV GP_PASSWORD=postgres
ENV GP_VERSION=6.19.4
ENV GPHOME=/usr/local/greenplum-db-${GP_VERSION}

RUN apt-get update -y &&\
    apt-get install -y sudo apt-utils software-properties-common curl locales gcc make maven unzip openjdk-11-jre libcurl4-openssl-dev &&\
    apt-get update -y &&\
    apt-get dist-upgrade -y &&\
    locale-gen en_US.UTF-8 &&\
    curl -SL -o greenplum-db.deb https://github.com/greenplum-db/gpdb/releases/download/${GP_VERSION}/greenplum-db-${GP_VERSION}-ubuntu18.04-amd64.deb &&\
    apt-get install -y ./greenplum-db.deb &&\
    rm greenplum-db.deb &&\
    rm -rf /var/lib/apt/lists/* &&\
    rm -rf /tmp/*  &&\
    groupadd -g 4321 gpdb &&\
    useradd -g 4321 -u 4321 --shell /bin/bash -m -d /home/gpdb gpdb &&\
    echo "gpdb:pivotal"|chpasswd &&\
    echo "gpdb        ALL=(ALL)       NOPASSWD: ALL" >> /etc/sudoers  &&\
    mkdir -p /srv/gpmaster  &&\
    mkdir -p /srv/gpdata && \
    chown -R gpdb:gpdb /home/gpdb &&\
    chown -R gpdb:gpdb /srv &&\
    chown -R gpdb:gpdb ${GPHOME}

# Install Go
RUN curl -LO https://go.dev/dl/go1.19.1.linux-amd64.tar.gz
RUN tar -C /usr/local -xzf go1.19.1.linux-amd64.tar.gz
ENV GOPATH=$HOME/go
ENV PATH=$PATH:/usr/local/go/bin:$GOPATH/bin

# PXF installation
USER gpdb
WORKDIR /home/gpdb

COPY prepare_env.sh prepare_env.sh

ENV JAVA_HOME=/usr/lib/jvm/java-11-openjdk-amd64
ENV PXF_HOME=/home/gpdb/pxf
ENV PXF_BASE=/home/gpdb/pxf-base
ENV PXF_JVM_OPTS='-Xmx512m -Xms256m'

RUN sudo chmod +x prepare_env.sh && ./prepare_env.sh &&\
    curl -LO https://github.com/greenplum-db/pxf/archive/refs/tags/release-6.4.2.tar.gz &&\
    tar -xzf release-6.4.2.tar.gz &&\
    source /usr/local/greenplum-db/greenplum_path.sh &&\
    sed -i 's/server install$/server install-server/g' pxf-release-6.4.2/Makefile &&\
    make -C pxf-release-6.4.2 &&\
    make -C pxf-release-6.4.2 install &&\
    $PXF_HOME/bin/pxf prepare

# Install PostgreSQL JDBC driver
RUN curl -LO https://jdbc.postgresql.org/download/postgresql-42.5.2.jar &&\
    cp postgresql-42.5.2.jar $PXF_HOME/lib/

COPY entrypoint.sh entrypoint.sh
RUN sudo chmod +x entrypoint.sh

ENTRYPOINT ["/bin/bash", "entrypoint.sh"]
