# FROM ubuntu:bionic
FROM pro100filipp/greenplum-with-pxf

COPY Dockerfile /

SHELL ["/bin/bash", "-c"]

# Greenplum installation
ENV MALLOC_ARENA_MAX=1
ENV TZ=UTC
ENV DEBIAN_FRONTEND=noninteractive
ENV GP_DB=testdb
ENV GP_USER=postgres
ENV GP_PASSWORD=postgres
ENV GP_VERSION=6.19.4
ENV GPHOME=/usr/local/greenplum-db-${GP_VERSION}
ENV GPADMIN_HOME=/home/gpadmin

USER root
WORKDIR /root

RUN apt-get update -y && \
    apt-get install -y sudo apt-utils software-properties-common curl locales gcc make maven unzip openjdk-11-jre libcurl4-openssl-dev wget lsof vim tcpdump telnet && \
    apt-get dist-upgrade -y && \
    locale-gen en_US.UTF-8 && \
    rm -rf /var/lib/apt/lists/* && \
    rm -rf /tmp/* && \
    userdel -r gpdb || true && \
    rm -rf /home/gpdb && \
    groupdel gpdb || true && \
    groupadd -g 4321 gpadmin && \
    useradd -g 4321 -u 4321 --shell /bin/bash -m -d ${GPADMIN_HOME} gpadmin && \
    echo "gpadmin:gpadmin" | chpasswd && \
    echo "gpadmin        ALL=(ALL)       NOPASSWD: ALL" >> /etc/sudoers && \
    mkdir -p /srv/gpmaster && \
    mkdir -p /srv/gpdata && \
    chown -R gpadmin:gpadmin ${GPADMIN_HOME} && \
    chown -R gpadmin:gpadmin /srv && \
    chown -R gpadmin:gpadmin ${GPHOME}

# Install Go
# RUN curl -LO https://go.dev/dl/go1.19.1.linux-amd64.tar.gz
COPY go1.19.1.linux-amd64.tar.gz /root/
RUN tar -C /usr/local -xzf go1.19.1.linux-amd64.tar.gz
ENV GOPATH=/usr/local/go
ENV PATH=$PATH:$GOPATH/bin

# PXF installation
USER gpadmin
WORKDIR ${GPADMIN_HOME}

COPY prepare_env.sh prepare_env.sh

ENV JAVA_HOME=/usr/lib/jvm/java-11-openjdk-amd64
ENV PXF_HOME=${GPADMIN_HOME}/pxf
ENV PXF_BASE=${GPADMIN_HOME}/pxf-base
ENV PXF_JVM_OPTS='-Xmx512m -Xms256m'

COPY pxf-release-6.4.2.tar.gz ${GPADMIN_HOME}/release-6.4.2.tar.gz
RUN sudo chmod +x prepare_env.sh && \
    ./prepare_env.sh && \
    tar -xzf release-6.4.2.tar.gz && \
    source /usr/local/greenplum-db/greenplum_path.sh && sed -i 's/server install$/server install-server/g' pxf-release-6.4.2/Makefile && \
    source /usr/local/greenplum-db/greenplum_path.sh && make -C pxf-release-6.4.2 && \
    source /usr/local/greenplum-db/greenplum_path.sh && make -C pxf-release-6.4.2 install && \
    $PXF_HOME/bin/pxf prepare

# Install PostgreSQL JDBC driver
# RUN curl -LO https://jdbc.postgresql.org/download/postgresql-42.5.2.jar
COPY postgresql-42.5.2.jar ${PXF_HOME}/lib/

COPY entrypoint.sh entrypoint.sh
RUN sudo chmod +x entrypoint.sh

ENTRYPOINT ["/bin/bash", "entrypoint.sh"]