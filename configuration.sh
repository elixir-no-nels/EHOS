#!/bin/bash

## Configuration file for variable creation

## Set the maximum and minimum number of nodes that will run
MAXNODES=6
MINNODES=2

## This is the base name that each execute node will get in the openstack interface. To make each node unique the main script will append the unix time
## at the time of creation. An example is "htcondorexecute-1515581225".
CONDORINSTANCENAME=htcondorexecute

## Name of the VM image that has a preconfigured HTCondor execute node installed on it
CONDORIMAGENAME=HTCondorExecute-18-06-18

## Securitu group name or names for openstack
readarray SECURITYGROUPS < <(echo "--security-group Pipeline-development"; echo "--security-group test"; echo "--security-group default")

## SSH key name for VM administration, this needs to exist already
SSHKEY=vgcn-testing

## Net id
readarray NIC < <(echo "--nic net-id=dualStack")

## The script needs to monitor the submitting user, or users, to count running jobs and do other things.
readarray SUBMITTINGUSERS < <(echo "-submitter galaxy"; echo "-submitter centos")

## Set flavor size for small or large VMs.
## m1.large: 2 cores, 8GB RAM
## m1.xlarge: 4 cores, 16B RAM
## m2.2xlarge: 8 cores, 32 GB RAM
## m2.4xlarge: 16 cores, 64 GB RAM
SMALL=m1.large
LARGE=m1.xlarge

## SSH key for the HTCondor execute node
SSHKEY=vgcn-testing

## Idle job VM creation variable, when the number of idle jobs is greater than this number, a larger VM is created to speed up the job execution
IDLEJOBVMC=40

## Large VM creation variable. This variable represents the number of CPUs that the job requests, if a job requests 4 CPUs, but no VM can run the job,
## then a new instance with 4 CPUs (m1.xlarge) is created. If this variable is changed to e.g 8, the $LARGE variable must be changed to the corresponding
## flavor too
LARGEVMC=4

## Sleep variables for the various sleep commands
SHORTSLEEP=15
LONGSLEEP=60