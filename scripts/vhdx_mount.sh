#!/bin/bash

PATH=$PATH:/mnt/c/Windows/system32

if [ ! -d /mnt/wsl/alpine_data ]; then
    mkdir -p /mnt/wsl/alpine_data
    wsl.exe -d alpine_data mount --bind /mnt/automount /mnt/wsl/alpine_data
fi

if [ ! -d /mnt/wsl/alpine_docker ]; then
    mkdir -p /mnt/wsl/alpine_docker
    wsl.exe -d alpine_docker mount --bind /mnt/automount /mnt/wsl/alpine_docker
fi

# mount external /home folder from Alpine distro
mountpoint -q /mnt/data || mount --bind /mnt/wsl/alpine_data /mnt/data
mountpoint -q /var/lib/docker || mount --bind /mnt/wsl/alpine_docker /var/lib/docker
