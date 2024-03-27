#!/bin/bash

sudo mkdir -p /mnt/data
# need this if docker isn't installed yet
sudo mkdir -p /var/lib/docker
# set up directories for mounting
sudo chown -R ${USER}:${USER} /mnt/data

# set up service to start alpine containers for mount points
sudo cp vhdx_mount.sh /usr/local/sbin/
sudo cp vhdx_mount.service /etc/systemd/system/
sudo systemctl daemon-reload
sudo systemctl enable vhdx_mount
sudo systemctl start vhdx_mount

if [ ! -f /mnt/data/this_is_alpine_data ]; then
    echo "************ ERROR ************"
    echo "* Setting up /mnt/data failed *"
    echo "*******************************"
else
    echo "Setting up /mnt/data worked"
fi

if [ ! -f /var/lib/docker/this_is_alpine_docker ]; then
    echo "*************** ERROR ***************"
    echo "* Setting up /var/lib/docker failed *"
    echo "*************************************"
else
    echo "Setting up /var/lib/docker worked"
fi
