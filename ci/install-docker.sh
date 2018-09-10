#!/bin/bash

set -x

cd /
curl -sL https://github.com/linyows/go-retry/releases/download/v0.3.1/linux_amd64.zip > retry.zip
unzip retry.zip
cp retry /usr/bin

apt-get -y remove docker docker-engine docker.io
apt-get -y install apt-transport-https ca-certificates curl software-properties-common
curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo apt-key add -
add-apt-repository "deb [arch=amd64] https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable"
apt-get update
apt-get -y install docker-ce
service docker restart
docker --version
docker info
