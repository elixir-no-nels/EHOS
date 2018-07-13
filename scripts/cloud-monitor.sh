#!/bin/bash
#You must run `source keystone_rc.sh` for the `openstack` command to work

source configuration.sh

watch '
echo -e "EHOS cloud monitor (CTRL-C to exit):\n";
condor_status;
condor_q ${SUBMITTINGUSERS[@]};
openstack server list'
