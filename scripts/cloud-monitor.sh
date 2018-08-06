#!/bin/bash
#You must run `source keystone_rc.sh` for the `openstack` command to work


#while true; do source configuration.sh && echo "EHOS cloud monitor (CTRL-C to exit):\n" && condor_status && condor_q ${SUBMITTINGUSERS[@]} && openstack server list && sleep 5 && clear; done
source ../configuration.sh

watch -d '
echo "EHOS cloud monitor (CTRL-C to exit)"
condor_status
condor_q -submitter centos -submitter galaxy
openstack server list'
