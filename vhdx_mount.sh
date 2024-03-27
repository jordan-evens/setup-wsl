#!/bin/bash

PATH=$PATH:/mnt/c/Windows/system32

if [ ! -d /mnt/wsl/alpine-data ]; then
    mkdir -p /mnt/wsl/alpine-data
    wsl.exe -d alpine-data mount --bind /mnt/automount /mnt/wsl/alpine-data
fi

if [ ! -d /mnt/wsl/alpine-docker ]; then
    mkdir -p /mnt/wsl/alpine-docker
    wsl.exe -d alpine-docker mount --bind /mnt/automount /mnt/wsl/alpine-docker
fi

# mount external /home folder from Alpine distro
mountpoint -q /mnt/data || mount --bind /mnt/wsl/alpine-data /mnt/data
mountpoint -q /var/lib/docker || mount --bind /mnt/wsl/alpine-docker /var/lib/docker
