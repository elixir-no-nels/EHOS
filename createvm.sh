#!/bin/bash

## Uncomment for CLI debugging
set -o xtrace

source "$(pwd)"/configuration.sh

VM=$(date +%s)
openstack server create --flavor $1 --image $CONDORIMAGENAME ${NIC[@]} ${SECURITYGROUPS[@]} --key-name $SSHKEY $CONDORINSTANCENAME-"${VM}"
