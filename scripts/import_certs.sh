#!/bin/bash
ls -1 *.cer | xargs -I {} openssl x509 -inform DER -in ./{} -out ~/{}.crt
sudo cp ~/*.crt /usr/local/share/ca-certificates/
sudo update-ca-certificates
