#!/bin/bash

## Enable repositories
# Repository for Singularity dependencies
sudo yum -y groupinstall "development tools"

# Repository for byobu
sudo yum -y install epel-release

# Add Docker repository
sudo yum-config-manager \
    --add-repo \
    https://download.docker.com/linux/centos/docker-ce.repo
sudo yum makecache fast

## Install dependencies
sudo yum -y install \
nano \
python-pip \
squashfs-tools \
gcc \
byobu \
wget \
python-devel \
libarchive-devel \
yum-utils \
device-mapper-persistent-data \
lvm2 \
docker-ce

## Install OpenStack CLI tool
sudo pip install python-openstackclient

## Start docker and enable automatic start at boot
sudo service docker start
sudo systemctl enable docker

## Enable rootless use of docker
sudo groupadd docker
sudo usermod -aG docker centos

## Install Singularity
VERSION=2.5.0
wget https://github.com/singularityware/singularity/releases/download/$VERSION/singularity-$VERSION.tar.gz
tar xvf singularity-$VERSION.tar.gz
cd singularity-$VERSION
./configure --prefix=/usr/local
make -j4
sudo make install

## Install HTCondor
# Add HTCondor repository
cd /etc/yum.repos.d
sudo wget https://research.cs.wisc.edu/htcondor/yum/repo.d/htcondor-development-rhel7.repo
sudo wget https://research.cs.wisc.edu/htcondor/yum/repo.d/htcondor-stable-rhel7.repo

# Import signing key 
sudo wget http://research.cs.wisc.edu/htcondor/yum/RPM-GPG-KEY-HTCondor
sudo rpm --import RPM-GPG-KEY-HTCondor

# Install condor
sudo yum -y install condor.x86_64

# Enable condor to run docker
sudo usermod -aG docker condor

# Start condor and enable it on start
sudo service condor start
sudo systemctl enable condor
