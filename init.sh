#!/bin/bash

# Tested on: Ubuntu 20.04 LTS (AWS)

if [[ $EUID -ne 0 ]]; then
   echo "UID != 0" 
   exit 1
fi
packages="docker docker.io docker-compose"
DEBIAN_FRONTEND=noninteractive apt-get -y update && apt-get -y dist-upgrade && apt-get install -y $packages && apt-get autoremove -y && apt-get clean -y && rm -rf /var/lib/apt/lists/*
for image in evilginx nginx-proxy gophish
do
    docker pull ghcr.io/thirdbyte/pacu:$image
    docker tag ghcr.io/thirdbyte/pacu:$image $image
    docker rmi ghcr.io/thirdbyte/pacu:$image
done
git clone https://github.com/thirdbyte/pacu /opt/pacu
mkdir -p /opt/pacu
cp /opt/pacu/setup.sh /usr/local/bin/pacu
chmod +x /usr/local/bin/pacu
