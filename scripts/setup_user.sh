#!/bin/bash

mkdir -p ~/.ssh

# copy ssh settings
if [ -d /mnt/c/Users/$USER/.ssh ]; then
    cp -R /mnt/c/Users/$USER/.ssh/ ~/.ssh
fi

if [ ! -f ~/.ssh/id_github ]; then
    if [ -f ./id_github ]; then
        echo "Using existing id_github key"
        cp id_github* ~/.ssh/
    else
        echo "Creating new id_github key"
        ssh-keygen -q -N "" -f ./id_github
    fi
fi

chmod 600 ~/.ssh/*
cat <<END >> ~/.ssh/config
Host github.com
  IdentityFile ~/.ssh/id_github
END

rm -f ~/.ssh/known_hosts*

printf "\nEnsure github SSH key is added:\n"
cat ~/.ssh/id_github.pub
