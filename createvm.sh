#!/bin/bash

## Uncomment for CLI debugging
set -o xtrace

source "$(pwd)"/configuration.sh

VM=$(date +%s)
## Vanilla without config
#openstack server create --flavor $1 --image $CONDORIMAGENAME ${NIC[@]} ${SECURITYGROUPS[@]} --key-name $SSHKEY $CONDORINSTANCENAME-"${VM}"

## Master node
#openstack server create --flavor $1 --image $CONDORIMAGENAME ${NIC[@]} ${SECURITYGROUPS[@]} --key-name $SSHKEY --user-data vm-config/master-config.yaml $CONDORINSTANCENAME-"${VM}"

##Execute node
openstack server create --flavor $1 --image $CONDORIMAGENAME ${NIC[@]} ${SECURITYGROUPS[@]} --key-name $SSHKEY --user-data vm-config/execute-config.yaml $CONDORINSTANCENAME-"${VM}"

## Submit node
#openstack server create --flavor $1 --image $CONDORIMAGENAME ${NIC[@]} ${SECURITYGROUPS[@]} --key-name $SSHKEY --user-data vm-config/submit-config.yaml $CONDORINSTANCENAME-"${VM}"

## Testing
#openstack server create --flavor $1 --image $CONDORIMAGENAME ${NIC[@]} ${SECURITYGROUPS[@]} --key-name $SSHKEY --user-data vm-config/kek.yaml $CONDORINSTANCENAME-"${VM}"

## Vanilla HTCondor
#openstack server create --flavor $1 --image "${CONDORIMAGENAME[@]}" ${NIC[@]} ${SECURITYGROUPS[@]} --key-name $SSHKEY --user-data vm-config/vanilla-condor.sh $CONDORINSTANCENAME-"${VM}"
