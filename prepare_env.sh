#!/bin/bash

echo "Preparing env..."
rm -rf /home/gpdb/.bashrc
echo "source ${GPHOME}/greenplum_path.sh" >> /home/gpdb/.bashrc
echo "export MASTER_DATA_DIRECTORY=/srv/gpmaster/gpsne-1" >> /home/gpdb/.bashrc
echo "" >> /home/gpdb/.bashrc
rm -rf /home/gpdb/.bash_profile
echo "if [ -f ~/.bashrc ]; then" >> /home/gpdb/.bash_profile
echo "    source ~/.bashrc" >> /home/gpdb/.bash_profile
echo "fi" >> /home/gpdb/.bash_profile
echo "" >> /home/gpdb/.bash_profile
echo "Preparation complete"
