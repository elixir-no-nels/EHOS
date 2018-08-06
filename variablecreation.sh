#!/bin/bash

## Uncomment for CLI debugging
#set -o xtrace

	## Display date
	date

	## Read configuration file
	source $(pwd)/configuration.sh

## Beginning of variable creation and main loop
	## Count the number of idle jobs
	IDLEJOBS=$(condor_q -l -submitter galaxy -submitter centos | grep -wc 'JobStatus = 1')
	echo "The number of idle jobs is $IDLEJOBS"

	## Count how many slots are available to calculate max jobs/slots
	MAXJOBS=$(condor_status -l | grep -i "TotalSlotCpus = [2,4,8]" | awk 'BEGIN{ total=0 } { total=total+$3 } END{ printf total }')
	echo "The execute node(s) can currently run "$MAXJOBS" jobs/threads"

	## Count how many jobs are currently running
	RUNNINGJOBS=$(condor_q -l -submitter galaxy -submitter centos | grep -wc 'JobStatus = 2')
	echo "The number of running jobs is $RUNNINGJOBS"

	## Create array with IP numbers of idle nodes
	readarray IDLENODES < <(condor_status -l | grep -iEo 'StartdIpAddr = "<[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}' | uniq -u | grep -Eo "[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}")
#	echo "The number of idle execute nodes is ${#IDLENODES[@]} and the idle node IP(s) is "$(printf '%s\n' "${IDLENODES[@]}")""

	## Create array with IP numbers of nodes that are running jobs
	readarray BUSYMACHINES < <(condor_q -l $(echo ${SUBMITTINGUSERS[@]}) | grep -oE "[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}" | sort -u)
	echo "The following execute nodes are running jobs: "$(printf '%s\n' "${BUSYMACHINES[@]}")""

	## Create array with name and IP address information of the execute nodes that have been created on openstack
	readarray EXECUTENODES < <(openstack server list --name $CONDORINSTANCENAME -c Name -c Networks -c Status -f value)
	echo "The total number of execute nodes in the pool is: ${#EXECUTENODES[@]}"
	i=0
	while [ $i -lt ${#EXECUTENODES[@]} ]; do
		printf "${EXECUTENODES[$i]}"
		let i=i+1;
	done

	## Variable that chooses which node to kill based on the conditionals below
	MACHINETOKILL=$(echo ${EXECUTENODES[@]} | grep -Eo "$CONDORINSTANCENAME-[0-9]* ACTIVE dualStack=${IDLENODES[0]}" | awk {' print $1 '})
#	echo "\$MACHINETOKILL is $MACHINETOKILL"

	## True or false variable that determines if a larger than standard VM should be created or not, only checks idle jobs
	REQCPUS=$(condor_q -l $(echo ${SUBMITTINGUSERS[@]}) | grep -o '^JobStatus = 1\|^RequestCpus = [4,8]' | grep -c "RequestCpus = 4")

	IPV6MACHINETOKILL=$(echo ${EXECUTENODES[@]} | grep -Eo "htcondorexecute-[0-9]* ACTIVE dualStack=[0-9]{4}\:[0-9]{3}\:[0-9]{1}\:[0-9]{4}\:\:[0-9]{2}[a-z]{1}[0-9]{1}" | awk {' print $1 '})

	## Display information about how many jobs are idle and how many execute nodes are available
#	echo "$IDLEJOBS jobs are idle and there's ${#EXECUTENODES[@]} execute node(s) available"
