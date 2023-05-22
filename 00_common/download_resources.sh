#!/bin/bash -e
set -e
set -u
set -o pipefail

DIR="$( cd "$( dirname "$0" )" && pwd )"

downloads_dir="$DIR/../artifact-downloads"

mkdir -p ${downloads_dir}

pushd ${downloads_dir}

# Docker for ubuntu (focal)

wget https://download.docker.com/linux/ubuntu/dists/focal/pool/stable/amd64/containerd.io_1.6.9-1_amd64.deb
wget https://download.docker.com/linux/ubuntu/dists/focal/pool/stable/amd64/docker-ce-cli_24.0.1-1~ubuntu.20.04~focal_amd64.deb
wget https://download.docker.com/linux/ubuntu/dists/focal/pool/stable/amd64/docker-ce_24.0.1-1~ubuntu.20.04~focal_amd64.deb
wget https://download.docker.com/linux/ubuntu/dists/focal/pool/stable/amd64/docker-compose-plugin_2.18.1-1~ubuntu.20.04~focal_amd64.deb


popd