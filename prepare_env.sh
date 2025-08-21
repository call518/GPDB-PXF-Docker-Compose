#!/bin/bash

echo "Preparing env..."
rm -rf /home/gpadmin/.bashrc
echo "alias ll='ls -al --color=auto'" >> /home/gpadmin/.bashrc
echo "source ${GPHOME}/greenplum_path.sh" >> /home/gpadmin/.bashrc
echo "export MASTER_DATA_DIRECTORY=/srv/gpmaster/gpsne-1" >> /home/gpadmin/.bashrc
echo "" >> /home/gpadmin/.bashrc
rm -rf /home/gpadmin/.bash_profile
echo "if [ -f ~/.bashrc ]; then" >> /home/gpadmin/.bash_profile
echo "    source ~/.bashrc" >> /home/gpadmin/.bash_profile
echo "fi" >> /home/gpadmin/.bash_profile
echo "" >> /home/gpadmin/.bash_profile
echo "Preparation complete"
