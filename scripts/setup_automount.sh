#!/bin/bash

echo "Setting up automount from alpine distros"

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

echo "Fixing permissions on automounted folders"
sudo chown -R $USER:$USER /mnt/data

# know we're going to use docker later but don't want this in that script
sudo groupadd docker
sudo usermod -aG docker $USER
sudo chown -R ${USER}:docker /var/lib/docker

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
