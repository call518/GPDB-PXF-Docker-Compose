#!/bin/bash

function install_pxf() {
    echo "Installing pxf..."
    make -C pxf-release-6.4.2 install
    export PATH=$PXF_HOME/bin:$PATH
    pxf prepare
}

function start_pxf_gpdb() {
    source "/home/gpdb/.bashrc"
    pxf start
    psql -d $GP_DB -c "create extension if not exists pxf;"
}

function start_singlenode_gpdb(){
    sudo service ssh start
    sleep infinity & PID=$!
    trap "kill $PID" INT TERM
    export HOME="/home/gpdb"
    cd $HOME
    source "/home/gpdb/.bashrc"
    export MASTER_HOSTNAME="$(hostname)"
    echo "$MASTER_HOSTNAME" > ./hostlist_singlenode
    if [ -f "/srv/gpmaster/gpsne-1/pg_hba.conf" ]; then
        echo "Skipping setup because we already have master files."
        gpssh-exkeys -f hostlist_singlenode
        gpstart -a
    else
        rm -rf ./gpinitsystem_singlenode
        echo "MASTER_MAX_CONNECT=16" >> ./gpinitsystem_singlenode
        echo "BATCH_DEFAULT=4" >> ./gpinitsystem_singlenode
        echo "ARRAY_NAME=\"GPDB SINGLENODE\"" >> ./gpinitsystem_singlenode
        echo "MACHINE_LIST_FILE=./hostlist_singlenode" >> ./gpinitsystem_singlenode
        echo "SEG_PREFIX=gpsne" >> ./gpinitsystem_singlenode
        echo "PORT_BASE=6000"  >> ./gpinitsystem_singlenode
        echo "declare -a DATA_DIRECTORY=(/srv/gpdata)" >> ./gpinitsystem_singlenode
        echo "MASTER_HOSTNAME=\"$MASTER_HOSTNAME\""  >> ./gpinitsystem_singlenode
        echo "MASTER_DIRECTORY=/srv/gpmaster" >> ./gpinitsystem_singlenode
        echo "MASTER_PORT=5432"  >> ./gpinitsystem_singlenode
        echo "TRUSTED_SHELL=ssh"   >> ./gpinitsystem_singlenode
        echo "CHECK_POINT_SEGMENTS=1" >> ./gpinitsystem_singlenode
        echo "ENCODING=UNICODE" >> ./gpinitsystem_singlenode
        echo "DATABASE_NAME=\"$GP_DB\"" >> ./gpinitsystem_singlenode
        echo "" >> ./gpinitsystem_singlenode
        gpssh-exkeys -f hostlist_singlenode
        gpinitsystem -c gpinitsystem_singlenode -a
        echo 'host     all         all           0.0.0.0/0  md5' >> /srv/gpmaster/gpsne-1/pg_hba.conf
        gpstop -u -a
        echo "Will create db user $GP_USER for $GP_DB"
        psql -c "create user $GP_USER with SUPERUSER password '$GP_PASSWORD';" "$GP_DB"
    fi
}

start_singlenode_gpdb
install_pxf
start_pxf_gpdb

echo "Waiting for sigint or sigterm"
wait
gpstop -a -M fast
pxf stop