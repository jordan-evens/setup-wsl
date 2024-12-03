#!/bin/bash

PATH=$PATH:/mnt/c/Windows/system32

if [ ! -d /mnt/wsl/alpine_data ]; then
    mkdir -p /mnt/wsl/alpine_data
    wsl.exe -d alpine_data mount --bind /mnt/automount /mnt/wsl/alpine_data
fi

# mount external /home folder from Alpine distro
mountpoint -q /mnt/data || mount --bind /mnt/wsl/alpine_data /mnt/data
