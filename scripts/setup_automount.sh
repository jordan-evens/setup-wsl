#!/bin/bash

echo "Setting up automount from alpine distros"

sudo mkdir -p /mnt/data

# set up service to start alpine containers for mount points
sudo cp vhdx_mount.sh /usr/local/sbin/
sudo cp vhdx_mount.service /etc/systemd/system/
sudo systemctl daemon-reload
sudo systemctl enable vhdx_mount
sudo systemctl start vhdx_mount

echo "Fixing permissions on automounted folders"
sudo chown -R $USER:$USER /mnt/data

if [ ! -f /mnt/data/this_is_alpine_data ]; then
    echo "************ ERROR ************"
    echo "* Setting up /mnt/data failed *"
    echo "*******************************"
else
    echo "Setting up /mnt/data worked"
fi
