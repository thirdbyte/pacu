#!/bin/bash

for image in evilginx gophish nginx-proxy
do
    docker build -t $image $image/.
done

docker rmi jwilder/nginx-proxy
docker rmi ubuntu:20.04
